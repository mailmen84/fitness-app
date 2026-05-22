"""Unit tests for the pure-Python helpers in scripts.import_off.

We don't test the DB path here; that needs an integration test with a real
Postgres. We only test the parsing/normalisation helpers because they're the
ones prone to bad input from the OFF CSV.
"""

from __future__ import annotations

from decimal import Decimal

from scripts.import_off import (
    _coerce_decimal,
    _pick_barcode,
    _pick_brand,
    _pick_image_url,
    _pick_name,
    _serving_amount,
    _build_nutrient_rows,
)


class TestCoerceDecimal:
    def test_returns_none_for_blank(self):
        assert _coerce_decimal('') is None
        assert _coerce_decimal('   ') is None
        assert _coerce_decimal(None) is None

    def test_parses_simple_number(self):
        assert _coerce_decimal('42') == Decimal('42.00')
        assert _coerce_decimal('42.5') == Decimal('42.50')

    def test_rejects_negative(self):
        assert _coerce_decimal('-1') is None

    def test_rejects_garbage(self):
        assert _coerce_decimal('not a number') is None
        assert _coerce_decimal('abc123') is None

    def test_clips_absurd_values(self):
        # 99999999 kcal -> clipped to None
        assert _coerce_decimal('99999999') is None


class TestPickName:
    def test_prefers_polish(self):
        row = {
            'product_name_pl': 'Czekolada mleczna',
            'product_name_en': 'Milk chocolate',
            'product_name': 'Chocolat au lait',
        }
        assert _pick_name(row) == 'Czekolada mleczna'

    def test_falls_back_to_english(self):
        row = {
            'product_name_pl': '',
            'product_name_en': 'Milk chocolate',
            'product_name': 'Chocolat au lait',
        }
        assert _pick_name(row) == 'Milk chocolate'

    def test_falls_back_to_generic(self):
        row = {'product_name': 'Chocolat au lait'}
        assert _pick_name(row) == 'Chocolat au lait'

    def test_returns_none_when_all_empty(self):
        assert _pick_name({'product_name': '', 'product_name_pl': '   '}) is None

    def test_truncates_to_160(self):
        long = 'a' * 300
        result = _pick_name({'product_name': long})
        assert result is not None
        assert len(result) == 160


class TestPickBrand:
    def test_takes_first_brand(self):
        assert _pick_brand({'brands': 'Wedel,Nestle,Milka'}) == 'Wedel'

    def test_strips_whitespace(self):
        assert _pick_brand({'brands': '  Wedel  '}) == 'Wedel'

    def test_returns_none_when_blank(self):
        assert _pick_brand({'brands': ''}) is None
        assert _pick_brand({}) is None


class TestPickBarcode:
    def test_strips_and_returns(self):
        assert _pick_barcode({'code': '  5901234567890  '}) == '5901234567890'

    def test_returns_none_when_blank(self):
        assert _pick_barcode({'code': ''}) is None
        assert _pick_barcode({}) is None

    def test_truncates(self):
        long = '1' * 50
        result = _pick_barcode({'code': long})
        assert result is not None
        assert len(result) == 32


class TestPickImageUrl:
    def test_prefers_small_front(self):
        row = {
            'image_front_small_url': 'https://example.org/small.jpg',
            'image_url': 'https://example.org/big.jpg',
        }
        assert _pick_image_url(row) == 'https://example.org/small.jpg'

    def test_falls_back_to_image_url(self):
        row = {'image_url': 'https://example.org/big.jpg'}
        assert _pick_image_url(row) == 'https://example.org/big.jpg'

    def test_rejects_non_http(self):
        row = {'image_url': 'data:image/png;base64,xxx'}
        assert _pick_image_url(row) is None

    def test_returns_none_when_missing(self):
        assert _pick_image_url({}) is None


class TestServingAmount:
    def test_uses_serving_quantity_when_present(self):
        assert _serving_amount({'serving_quantity': '30'}) == Decimal('30.00')

    def test_falls_back_to_100g(self):
        assert _serving_amount({}) == Decimal('100.00')
        assert _serving_amount({'serving_quantity': ''}) == Decimal('100.00')

    def test_rejects_zero(self):
        # 0 -> fallback to 100g (a product can't have 0g serving)
        assert _serving_amount({'serving_quantity': '0'}) == Decimal('100.00')


class TestBuildNutrientRows:
    def test_includes_only_present_macros(self):
        import uuid

        food_id = uuid.uuid4()
        row = {
            'energy-kcal_100g': '250',
            'proteins_100g': '10',
            'carbohydrates_100g': '',  # missing - should be skipped
            'fat_100g': '5',
        }
        result = _build_nutrient_rows(food_id, row)
        codes = [r[1] for r in result]
        assert codes == ['calories', 'protein', 'fat']

    def test_empty_row_returns_empty(self):
        import uuid

        result = _build_nutrient_rows(uuid.uuid4(), {})
        assert result == []
