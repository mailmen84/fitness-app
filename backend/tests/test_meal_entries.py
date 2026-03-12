from decimal import Decimal
from types import SimpleNamespace
from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import get_current_user, get_meals_service
from app.domain.meals.schemas import DeleteResponse, TodayMealEntryRead
from app.main import app

client = TestClient(app)


class FakeMealsService:
    async def create_meal_entry(self, user_id, payload):  # noqa: ANN001
        return TodayMealEntryRead(
            id=uuid4(),
            meal_id=uuid4(),
            food_id=payload.food_id,
            food_name='Greek Yogurt',
            quantity=payload.quantity,
            unit=payload.unit,
            calories=Decimal('100.00'),
            protein=Decimal('17.00'),
            carbs=Decimal('6.00'),
            fat=Decimal('0.00'),
            notes=payload.notes,
        )

    async def update_meal_entry(self, user_id, entry_id, payload):  # noqa: ANN001
        return TodayMealEntryRead(
            id=entry_id,
            meal_id=uuid4(),
            food_id=uuid4(),
            food_name='Greek Yogurt',
            quantity=payload.quantity or Decimal('170.00'),
            unit=payload.unit or 'g',
            calories=Decimal('100.00'),
            protein=Decimal('17.00'),
            carbs=Decimal('6.00'),
            fat=Decimal('0.00'),
            notes=payload.notes,
        )

    async def delete_meal_entry(self, user_id, entry_id):  # noqa: ANN001
        return DeleteResponse()


async def override_current_user():
    return SimpleNamespace(id=uuid4())


def override_meals_service() -> FakeMealsService:
    return FakeMealsService()


def test_create_meal_entry_endpoint_returns_entry_shape() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_meals_service] = override_meals_service

    response = client.post(
        '/api/v1/meals/entries',
        json={
            'date': '2026-03-10',
            'meal_section': 'breakfast',
            'food_id': str(uuid4()),
            'quantity': 170,
            'unit': 'g',
        },
    )

    app.dependency_overrides.clear()

    assert response.status_code == 201
    payload = response.json()
    assert payload['food_name'] == 'Greek Yogurt'
    assert payload['unit'] == 'g'


def test_delete_meal_entry_endpoint_returns_delete_shape() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_meals_service] = override_meals_service

    response = client.delete(f'/api/v1/meals/entries/{uuid4()}')

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['ok'] is True
