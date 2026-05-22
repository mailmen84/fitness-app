"""Quick stats helper to peek at the foods table after an import.

Usage:
    python -m scripts.foods_stats
"""

from __future__ import annotations

import os
import sys

import psycopg


def main() -> int:
    url = os.environ.get('BACKEND_DATABASE_URL') or os.environ.get('DATABASE_URL')
    if not url:
        print('ERROR: BACKEND_DATABASE_URL not set', file=sys.stderr)
        return 2
    dsn = url.replace('+asyncpg', '').replace('postgresql+psycopg', 'postgresql')

    conn = psycopg.connect(dsn, autocommit=True)
    try:
        with conn.cursor() as cur:
            cur.execute('SELECT COUNT(*) FROM foods')
            total = cur.fetchone()[0]
            cur.execute("SELECT source, COUNT(*) FROM foods GROUP BY source ORDER BY 2 DESC")
            by_source = cur.fetchall()
            cur.execute('SELECT COUNT(*) FROM food_nutrients')
            total_nutrients = cur.fetchone()[0]
            cur.execute(
                "SELECT name, brand FROM foods WHERE name ILIKE %s LIMIT 5",
                ('%potato%',),
            )
            potato_samples = cur.fetchall()
            cur.execute(
                "SELECT name, brand FROM foods WHERE name ILIKE %s LIMIT 5",
                ('%ziemniak%',),
            )
            ziemniak_samples = cur.fetchall()

        print(f'Total foods: {total:,}')
        print(f'Total nutrients: {total_nutrients:,}')
        print()
        print('By source:')
        for source, count in by_source:
            print(f'  {source}: {count:,}')
        print()
        print('Sample "potato" matches:')
        for name, brand in potato_samples:
            print(f'  {name!r} ({brand or "no brand"})')
        print()
        print('Sample "ziemniak" matches:')
        for name, brand in ziemniak_samples:
            print(f'  {name!r} ({brand or "no brand"})')

    finally:
        conn.close()

    return 0


if __name__ == '__main__':
    sys.exit(main())
