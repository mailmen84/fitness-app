"""Thin async client for the public OpenFoodFacts product API.

Endpoint reference: https://openfoodfacts.github.io/openfoodfacts-server/api/
We use API v2 with a `fields` filter to keep payloads small and predictable.
"""

from __future__ import annotations

import asyncio
import time
from decimal import Decimal, InvalidOperation
from typing import Any

import httpx

from app.domain.foods.schemas import OpenFoodFactsLookup

_BASE_URL = 'https://world.openfoodfacts.org/api/v2/product'
# Fields we actually consume on the client. Keeping the list explicit shrinks
# the payload from ~50KB to a few KB and makes the contract obvious.
_FIELDS = ','.join(
    [
        'code',
        'product_name',
        'product_name_pl',
        'product_name_en',
        'brands',
        'serving_size',
        'serving_quantity',
        'image_front_small_url',
        'image_url',
        'nutriments',
    ]
)
_DEFAULT_TIMEOUT = httpx.Timeout(5.0, connect=3.0)
_USER_AGENT = 'fitness-app/0.1 (https://github.com/mailmen84/fitness-app)'


class OpenFoodFactsClient:
    """Async OFF client with a small in-process TTL cache.

    The cache is per-process and per-instance. It stops back-to-back rescans
    of the same barcode in one session from re-hitting OFF.
    """

    def __init__(self, *, cache_ttl_seconds: int = 3600) -> None:
        self._cache: dict[str, tuple[float, OpenFoodFactsLookup]] = {}
        self._ttl = cache_ttl_seconds
        self._lock = asyncio.Lock()

    async def lookup(self, barcode: str) -> OpenFoodFactsLookup:
        normalized = barcode.strip()
        if not normalized:
            return OpenFoodFactsLookup(barcode=barcode, found=False)

        cached = self._get_cached(normalized)
        if cached is not None:
            return cached

        url = f'{_BASE_URL}/{normalized}.json'
        params = {'fields': _FIELDS}
        headers = {'User-Agent': _USER_AGENT, 'Accept': 'application/json'}

        try:
            async with httpx.AsyncClient(timeout=_DEFAULT_TIMEOUT) as client:
                response = await client.get(url, params=params, headers=headers)
        except (httpx.TimeoutException, httpx.TransportError):
            return OpenFoodFactsLookup(barcode=normalized, found=False)

        if response.status_code != 200:
            return OpenFoodFactsLookup(barcode=normalized, found=False)

        try:
            payload = response.json()
        except ValueError:
            return OpenFoodFactsLookup(barcode=normalized, found=False)

        if int(payload.get('status', 0)) != 1:
            result = OpenFoodFactsLookup(barcode=normalized, found=False)
            self._set_cached(normalized, result)
            return result

        result = self._parse_product(normalized, payload.get('product') or {})
        self._set_cached(normalized, result)
        return result

    # --- Internals ---

    def _get_cached(self, key: str) -> OpenFoodFactsLookup | None:
        entry = self._cache.get(key)
        if entry is None:
            return None
        stored_at, value = entry
        if time.monotonic() - stored_at > self._ttl:
            self._cache.pop(key, None)
            return None
        return value

    def _set_cached(self, key: str, value: OpenFoodFactsLookup) -> None:
        self._cache[key] = (time.monotonic(), value)

    @staticmethod
    def _coerce_decimal(value: Any) -> Decimal | None:
        if value is None or value == '':
            return None
        try:
            decimal_value = Decimal(str(value))
        except (InvalidOperation, ValueError, TypeError):
            return None
        if decimal_value < 0:
            return None
        return decimal_value.quantize(Decimal('0.01'))

    @staticmethod
    def _pick_name(product: dict[str, Any]) -> str | None:
        for key in ('product_name_pl', 'product_name_en', 'product_name'):
            value = product.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()[:160]
        return None

    @staticmethod
    def _pick_brand(product: dict[str, Any]) -> str | None:
        brands = product.get('brands')
        if not isinstance(brands, str) or not brands.strip():
            return None
        # OFF stores brands as comma-separated; take the first.
        first = brands.split(',')[0].strip()
        return first[:160] if first else None

    @staticmethod
    def _pick_serving(product: dict[str, Any]) -> tuple[Decimal | None, str | None]:
        # Prefer numeric serving_quantity (always grams in OFF) when present;
        # fallback to per-100g.
        quantity = OpenFoodFactsClient._coerce_decimal(product.get('serving_quantity'))
        if quantity is not None and quantity > 0:
            return quantity, 'g'
        return Decimal('100.00'), 'g'

    @classmethod
    def _parse_product(cls, barcode: str, product: dict[str, Any]) -> OpenFoodFactsLookup:
        name = cls._pick_name(product)
        if name is None:
            return OpenFoodFactsLookup(barcode=barcode, found=False)

        brand = cls._pick_brand(product)
        serving_amount, serving_unit = cls._pick_serving(product)

        nutriments = product.get('nutriments') or {}
        # Nutriments are per 100g by default; if we have an explicit serving, OFF
        # also exposes `*_serving` keys. Prefer them when serving != 100g.
        suffix = '_serving' if serving_amount and serving_amount != Decimal('100.00') else '_100g'

        def _read(key: str) -> Decimal | None:
            value = nutriments.get(f'{key}{suffix}')
            if value is None:
                # fallback to per-100g if serving variant absent
                value = nutriments.get(f'{key}_100g')
            return cls._coerce_decimal(value)

        # OFF uses `energy-kcal` for calories; key has a hyphen.
        calories = cls._coerce_decimal(nutriments.get(f'energy-kcal{suffix}'))
        if calories is None:
            calories = cls._coerce_decimal(nutriments.get('energy-kcal_100g'))
        protein = _read('proteins')
        carbs = _read('carbohydrates')
        fat = _read('fat')

        is_complete = all(v is not None for v in (calories, protein, carbs, fat))

        image_url = product.get('image_front_small_url') or product.get('image_url')
        if not isinstance(image_url, str):
            image_url = None

        return OpenFoodFactsLookup(
            barcode=barcode,
            found=True,
            is_complete=is_complete,
            name=name,
            brand=brand,
            default_serving_amount=serving_amount,
            default_serving_unit=serving_unit,
            calories=calories,
            protein=protein,
            carbs=carbs,
            fat=fat,
            image_url=image_url,
            source_url=f'https://world.openfoodfacts.org/product/{barcode}',
        )
