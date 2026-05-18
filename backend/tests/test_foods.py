from decimal import Decimal
from types import SimpleNamespace
from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import get_current_user, get_foods_service
from app.domain.foods.schemas import (
    FoodDetailRead,
    FoodNutrientRead,
    FoodSearchResultRead,
    FoodSearchResultsRead,
    OpenFoodFactsLookup,
)
from app.main import app

client = TestClient(app)


async def override_current_user():
    return SimpleNamespace(id=uuid4())


class FakeFoodsService:
    async def search_foods(self, query: str, limit: int = 20) -> FoodSearchResultsRead:
        return FoodSearchResultsRead(
            query=query,
            items=[
                FoodSearchResultRead(
                    id=uuid4(),
                    name='Greek Yogurt',
                    brand='Demo Pantry',
                    default_serving_amount=Decimal('170.00'),
                    default_serving_unit='g',
                    is_verified=True,
                    calories=Decimal('100.00'),
                    protein=Decimal('17.00'),
                    carbs=Decimal('6.00'),
                    fat=Decimal('0.00'),
                )
            ],
        )

    async def get_food_detail(self, food_id):  # noqa: ANN001
        return FoodDetailRead(
            id=uuid4(),
            created_at='2026-03-10T00:00:00Z',
            updated_at='2026-03-10T00:00:00Z',
            name='Greek Yogurt',
            brand='Demo Pantry',
            default_serving_amount=Decimal('170.00'),
            default_serving_unit='g',
            source='development_seed',
            is_verified=True,
            calories=Decimal('100.00'),
            protein=Decimal('17.00'),
            carbs=Decimal('6.00'),
            fat=Decimal('0.00'),
            nutrients=[
                FoodNutrientRead(
                    id=uuid4(),
                    created_at='2026-03-10T00:00:00Z',
                    updated_at='2026-03-10T00:00:00Z',
                    food_id=uuid4(),
                    nutrient_code='protein',
                    nutrient_name='Protein',
                    amount=Decimal('17.00'),
                    unit='g',
                    display_order=20,
                )
            ],
        )


def override_foods_service() -> FakeFoodsService:
    return FakeFoodsService()


def test_food_search_endpoint_returns_seedable_shape() -> None:
    app.dependency_overrides[get_foods_service] = override_foods_service

    response = client.get('/api/v1/foods/search', params={'q': 'yogurt'})

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['query'] == 'yogurt'
    assert payload['items'][0]['name'] == 'Greek Yogurt'


def test_food_detail_endpoint_returns_macro_fields() -> None:
    app.dependency_overrides[get_foods_service] = override_foods_service

    response = client.get(f'/api/v1/foods/{uuid4()}')

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['name'] == 'Greek Yogurt'
    assert payload['protein'] in ('17.00', 17.0, 17)


# --- Barcode + OpenFoodFacts flow ---

_FIXED_FOOD_ID = uuid4()


def _detail_with(name: str, barcode: str | None) -> FoodDetailRead:
    return FoodDetailRead(
        id=_FIXED_FOOD_ID,
        created_at='2026-05-18T00:00:00Z',
        updated_at='2026-05-18T00:00:00Z',
        name=name,
        brand='Test Brand',
        barcode=barcode,
        default_serving_amount=Decimal('100.00'),
        default_serving_unit='g',
        source='user',
        is_verified=False,
        calories=Decimal('250.00'),
        protein=Decimal('10.00'),
        carbs=Decimal('30.00'),
        fat=Decimal('8.00'),
        nutrients=[],
    )


class BarcodeFoodsService:
    """Fake service exposing the new barcode-related methods."""

    def __init__(
        self,
        *,
        local_hit: FoodDetailRead | None = None,
        off_response: OpenFoodFactsLookup | None = None,
        create_result: FoodDetailRead | None = None,
        create_error: str | None = None,
    ) -> None:
        self.local_hit = local_hit
        self.off_response = off_response
        self.create_result = create_result
        self.create_error = create_error

    async def get_food_by_barcode(self, barcode):  # noqa: ANN001
        return self.local_hit

    async def lookup_openfoodfacts(self, barcode):  # noqa: ANN001
        if self.off_response is not None:
            return self.off_response
        return OpenFoodFactsLookup(barcode=barcode, found=False)

    async def create_food_from_request(self, payload):  # noqa: ANN001
        if self.create_error is not None:
            raise ValueError(self.create_error)
        return self.create_result or _detail_with(payload.name, payload.barcode)


def test_by_barcode_returns_local_food_when_found() -> None:
    service = BarcodeFoodsService(local_hit=_detail_with('Local Yogurt', '5901234123457'))
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_foods_service] = lambda: service

    response = client.get('/api/v1/foods/by-barcode/5901234123457')

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['name'] == 'Local Yogurt'
    assert payload['barcode'] == '5901234123457'


def test_by_barcode_returns_404_when_not_in_local_db() -> None:
    service = BarcodeFoodsService(local_hit=None)
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_foods_service] = lambda: service

    response = client.get('/api/v1/foods/by-barcode/0000000000000')

    app.dependency_overrides.clear()

    assert response.status_code == 404


def test_openfoodfacts_lookup_returns_draft_when_complete() -> None:
    draft = OpenFoodFactsLookup(
        barcode='5901234123457',
        found=True,
        is_complete=True,
        name='Greek Yogurt',
        brand='OFF Brand',
        default_serving_amount=Decimal('100.00'),
        default_serving_unit='g',
        calories=Decimal('60.00'),
        protein=Decimal('5.00'),
        carbs=Decimal('4.00'),
        fat=Decimal('2.00'),
        source_url='https://world.openfoodfacts.org/product/5901234123457',
    )
    service = BarcodeFoodsService(off_response=draft)
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_foods_service] = lambda: service

    response = client.get('/api/v1/foods/openfoodfacts/5901234123457')

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['found'] is True
    assert payload['is_complete'] is True
    assert payload['name'] == 'Greek Yogurt'


def test_openfoodfacts_lookup_returns_not_found_payload() -> None:
    service = BarcodeFoodsService(off_response=OpenFoodFactsLookup(barcode='9999', found=False))
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_foods_service] = lambda: service

    response = client.get('/api/v1/foods/openfoodfacts/9999')

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['found'] is False
    assert payload['is_complete'] is False


def test_create_food_endpoint_persists_payload() -> None:
    service = BarcodeFoodsService(create_result=_detail_with('My Bread', '111222333'))
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_foods_service] = lambda: service

    response = client.post(
        '/api/v1/foods',
        json={
            'name': 'My Bread',
            'brand': 'Local Bakery',
            'barcode': '111222333',
            'default_serving_amount': '50.00',
            'default_serving_unit': 'g',
            'source': 'user',
            'calories': '120.00',
            'protein': '4.00',
            'carbs': '22.00',
            'fat': '1.50',
        },
    )

    app.dependency_overrides.clear()

    assert response.status_code == 201
    payload = response.json()
    assert payload['name'] == 'My Bread'


def test_create_food_endpoint_returns_409_on_duplicate_barcode() -> None:
    service = BarcodeFoodsService(create_error='barcode_taken')
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_foods_service] = lambda: service

    response = client.post(
        '/api/v1/foods',
        json={
            'name': 'Duplicate',
            'barcode': '5901234123457',
            'calories': '0',
            'protein': '0',
            'carbs': '0',
            'fat': '0',
        },
    )

    app.dependency_overrides.clear()

    assert response.status_code == 409

