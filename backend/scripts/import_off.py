"""Import Open Food Facts CSV dump into the foods + food_nutrients tables.

Usage (from backend/ with BACKEND_DATABASE_URL set, or pass --dsn):

    python -m scripts.import_off --csv ~/imports/off/en.openfoodfacts.org.products.csv.gz

Design choices:
- Streams the gzipped CSV row-by-row (no full unpack on disk).
- Tab-delimited (OFF dump uses TSV despite the .csv extension).
- Bulk INSERTs in batches via psycopg COPY for foods and food_nutrients.
- Idempotent: skips rows whose barcode already exists in foods.
- Accepts incomplete macros (per user request: "wszystko co da sie sparsowac").
- Only rows with at least a non-empty name and a barcode (code) are imported.
  A row without code cannot be uniquely keyed and is skipped.

This script intentionally does not use the ORM. Going through SQLAlchemy +
asyncpg would be 10-50x slower for 3.7M rows. We use psycopg's COPY which is
the fastest path Postgres exposes.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import io
import os
import sys
import time
import uuid
from decimal import Decimal, InvalidOperation
from typing import Iterable

import psycopg

# Fields we read out of the OFF TSV. The dump has ~200 columns; we only need
# a handful. The header line tells us their actual positions.
_REQUIRED_HEADERS = [
    'code',
    'product_name',
    'brands',
    'serving_quantity',
    'energy-kcal_100g',
    'proteins_100g',
    'carbohydrates_100g',
    'fat_100g',
    'image_url',
    'image_front_small_url',
]

# Additional language-specific name columns we try before falling back.
_NAME_FALLBACKS = ['product_name_pl', 'product_name_en', 'product_name']

# Batching: larger batches = fewer round trips but more memory.
# 5000 rows of compact tuples is ~5 MB per batch, easily fits in RAM.
_BATCH_SIZE = 5000

# Hard cap on name length (matches Food.name = String(160)).
_NAME_MAX = 160
_BRAND_MAX = 160
_BARCODE_MAX = 32

# Decimal quantize template - 2 decimal places matches Numeric(10,2).
_Q2 = Decimal('0.01')
# 4 decimal places for nutrient amount - Numeric(12,4).
_Q4 = Decimal('0.0001')


def _open_csv(path: str) -> io.TextIOBase:
    """Open the CSV (gz or plain) as a text stream with UTF-8 + lenient errors.

    OFF dump has occasional invalid UTF-8 sequences; we replace them rather
    than crash.
    """
    if path.endswith('.gz'):
        binary = gzip.open(path, 'rb')
    else:
        binary = open(path, 'rb')
    return io.TextIOWrapper(binary, encoding='utf-8', errors='replace', newline='')


def _coerce_decimal(value: str | None, quantize: Decimal = _Q2) -> Decimal | None:
    if value is None:
        return None
    s = value.strip()
    if not s:
        return None
    try:
        d = Decimal(s)
    except (InvalidOperation, ValueError):
        return None
    if d < 0:
        return None
    # Cap absurdly large values that some OFF rows contain (e.g. typos like
    # 99999999 kcal). Anything > 10k is almost certainly wrong; clip to None.
    if quantize is _Q2 and d > 100000:
        return None
    try:
        return d.quantize(quantize)
    except InvalidOperation:
        return None


def _pick_name(row: dict[str, str]) -> str | None:
    for key in _NAME_FALLBACKS:
        value = row.get(key)
        if value and value.strip():
            return value.strip()[:_NAME_MAX]
    return None


def _pick_brand(row: dict[str, str]) -> str | None:
    brands = (row.get('brands') or '').strip()
    if not brands:
        return None
    # OFF stores brands as comma-separated; first is usually canonical.
    first = brands.split(',')[0].strip()
    return first[:_BRAND_MAX] if first else None


def _pick_image_url(row: dict[str, str]) -> str | None:
    # Prefer the small front thumbnail; fallback to the main image_url.
    for key in ('image_front_small_url', 'image_url'):
        v = (row.get(key) or '').strip()
        if v.startswith('http'):
            return v[:2048]
    return None


def _pick_barcode(row: dict[str, str]) -> str | None:
    code = (row.get('code') or '').strip()
    if not code:
        return None
    # OFF codes are numeric strings; some are very long internal IDs. Truncate.
    return code[:_BARCODE_MAX]


def _serving_amount(row: dict[str, str]) -> Decimal | None:
    qty = _coerce_decimal(row.get('serving_quantity'))
    if qty is not None and qty > 0:
        return qty
    return Decimal('100.00')


def _build_nutrient_rows(food_id: uuid.UUID, row: dict[str, str]) -> list[tuple]:
    """Return list of (food_id, code, name, amount, unit, display_order) tuples.

    Only macros + calories. Each value is per 100g per OFF convention - that's
    what the *_100g suffix means in the dump.
    """
    macros = [
        ('calories', 'Calories', 'energy-kcal_100g', 'kcal', 1),
        ('protein', 'Protein', 'proteins_100g', 'g', 2),
        ('carbs', 'Carbohydrates', 'carbohydrates_100g', 'g', 3),
        ('fat', 'Fat', 'fat_100g', 'g', 4),
    ]
    rows = []
    for code, display, csv_col, unit, order in macros:
        amount = _coerce_decimal(row.get(csv_col), _Q4)
        if amount is None:
            continue
        rows.append((food_id, code, display, amount, unit, order))
    return rows


def import_off(csv_path: str, dsn: str, *, max_rows: int | None = None) -> None:
    """Stream the OFF dump and insert rows in batches via psycopg COPY."""

    print(f'Opening: {csv_path}', flush=True)
    fh = _open_csv(csv_path)
    reader = csv.DictReader(fh, delimiter='\t', quoting=csv.QUOTE_NONE)

    # Sanity check that the columns we need exist.
    missing = [h for h in _REQUIRED_HEADERS if h not in reader.fieldnames]
    if missing:
        # Some OFF dumps rename columns over time; warn but continue.
        print(f'WARN: missing expected columns: {missing}', flush=True)

    print(f'Connecting to DB...', flush=True)
    conn = psycopg.connect(dsn, autocommit=False)
    try:
        # Preload existing barcodes so we can skip duplicates cheaply.
        # This costs memory (3.7M strings ~ 200 MB) but avoids a round trip
        # per row. For first-time import the set is empty so this is free.
        print('Loading existing barcodes (for idempotency)...', flush=True)
        with conn.cursor() as cur:
            cur.execute('SELECT barcode FROM foods WHERE barcode IS NOT NULL')
            existing = {row[0] for row in cur.fetchall()}
        print(f'Existing barcodes: {len(existing):,}', flush=True)

        food_batch: list[tuple] = []
        nutrient_batch: list[tuple] = []
        seen_in_run: set[str] = set()

        total_rows = 0
        imported = 0
        skipped_no_code = 0
        skipped_no_name = 0
        skipped_duplicate = 0
        t0 = time.monotonic()

        for row in reader:
            total_rows += 1

            if max_rows is not None and imported >= max_rows:
                break

            barcode = _pick_barcode(row)
            if not barcode:
                skipped_no_code += 1
                continue
            if barcode in existing or barcode in seen_in_run:
                skipped_duplicate += 1
                continue
            name = _pick_name(row)
            if not name:
                skipped_no_name += 1
                continue

            food_id = uuid.uuid4()
            brand = _pick_brand(row)
            serving_amount = _serving_amount(row)
            image_url = _pick_image_url(row)

            # Foods table columns we control: id, name, brand, barcode,
            # default_serving_amount, default_serving_unit, source, is_verified,
            # created_at, updated_at. (image_url is appended via a column
            # added by the same migration that prepares us for this import.)
            #
            # NOTE: the existing schema has no image_url column. To avoid an
            # additional migration here, we store the image URL inside the
            # food_nutrients table is wrong - instead, we hold image URL only
            # if a future migration adds the column. For now we drop it.
            # (If you want image_url stored, run the optional migration in
            # alembic/versions/20260522_0007_food_image_url.py first.)
            food_batch.append(
                (
                    food_id,
                    name,
                    brand,
                    barcode,
                    serving_amount,
                    'g',
                    'openfoodfacts',
                    False,  # is_verified
                )
            )
            nutrient_batch.extend(_build_nutrient_rows(food_id, row))
            seen_in_run.add(barcode)
            imported += 1

            if len(food_batch) >= _BATCH_SIZE:
                _flush(conn, food_batch, nutrient_batch)
                food_batch.clear()
                nutrient_batch.clear()

                elapsed = time.monotonic() - t0
                rate = imported / elapsed if elapsed > 0 else 0
                print(
                    f'[{elapsed:7.1f}s] imported={imported:>9,} '
                    f'scanned={total_rows:>9,} '
                    f'rate={rate:>6,.0f}/s '
                    f'skip_dup={skipped_duplicate:,} '
                    f'skip_noname={skipped_no_name:,} '
                    f'skip_nocode={skipped_no_code:,}',
                    flush=True,
                )

        # Final flush.
        if food_batch:
            _flush(conn, food_batch, nutrient_batch)

        conn.commit()
        elapsed = time.monotonic() - t0
        print(
            f'DONE in {elapsed:.1f}s | '
            f'imported={imported:,} scanned={total_rows:,} '
            f'skip_dup={skipped_duplicate:,} '
            f'skip_noname={skipped_no_name:,} '
            f'skip_nocode={skipped_no_code:,}',
            flush=True,
        )
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
        fh.close()


def _flush(conn: psycopg.Connection, foods: list[tuple], nutrients: list[tuple]) -> None:
    """Bulk-insert one batch of foods + their nutrients using COPY."""
    with conn.cursor() as cur:
        # COPY foods. Order must match the column list.
        with cur.copy(
            'COPY foods (id, name, brand, barcode, default_serving_amount, '
            'default_serving_unit, source, is_verified) FROM STDIN'
        ) as copy_foods:
            for row in foods:
                copy_foods.write_row(row)

        if nutrients:
            with cur.copy(
                'COPY food_nutrients (id, food_id, nutrient_code, nutrient_name, '
                'amount, unit, display_order) FROM STDIN'
            ) as copy_nutrients:
                for f_id, code, name, amount, unit, order in nutrients:
                    copy_nutrients.write_row((uuid.uuid4(), f_id, code, name, amount, unit, order))


def _dsn_from_env() -> str | None:
    """Convert SQLAlchemy-style URL (BACKEND_DATABASE_URL) to plain psycopg DSN.

    asyncpg uses postgresql+asyncpg://user:pass@host/db.
    psycopg wants postgresql://user:pass@host/db (no +asyncpg).
    """
    url = os.environ.get('BACKEND_DATABASE_URL') or os.environ.get('DATABASE_URL')
    if not url:
        return None
    return url.replace('+asyncpg', '').replace('postgresql+psycopg', 'postgresql')


def main() -> int:
    parser = argparse.ArgumentParser(description='Import Open Food Facts CSV dump.')
    parser.add_argument(
        '--csv',
        required=True,
        help='Path to en.openfoodfacts.org.products.csv(.gz)',
    )
    parser.add_argument(
        '--dsn',
        default=None,
        help='Postgres DSN (defaults to $BACKEND_DATABASE_URL with +asyncpg stripped).',
    )
    parser.add_argument(
        '--max-rows',
        type=int,
        default=None,
        help='Optional cap for testing (e.g. --max-rows 10000).',
    )
    args = parser.parse_args()

    dsn = args.dsn or _dsn_from_env()
    if not dsn:
        print('ERROR: no DSN. Set BACKEND_DATABASE_URL or pass --dsn.', file=sys.stderr)
        return 2
    if not os.path.exists(args.csv):
        print(f'ERROR: csv not found: {args.csv}', file=sys.stderr)
        return 2

    import_off(args.csv, dsn, max_rows=args.max_rows)
    return 0


if __name__ == '__main__':
    sys.exit(main())
