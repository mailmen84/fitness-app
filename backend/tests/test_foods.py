from decimal import Decimal
from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import get_foods_service
from app.domain.foods.schemas import FoodDetailRead, FoodNutrientRead, FoodSearchResultRead, FoodSearchResultsRead
from app.main import app

client = TestClient(app)


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

