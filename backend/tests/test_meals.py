from datetime import date
from decimal import Decimal
from types import SimpleNamespace
from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import get_current_user, get_meals_service
from app.domain.meals.schemas import (
    MealSectionCode,
    TodayMealEntryRead,
    TodayMealsRead,
    TodayMealSectionRead,
)
from app.main import app

client = TestClient(app)


class FakeMealsService:
    async def get_day_meals(self, user_id, selected_date: date) -> TodayMealsRead:  # noqa: ANN001
        breakfast_entry = TodayMealEntryRead(
            id=uuid4(),
            meal_id=uuid4(),
            food_id=uuid4(),
            food_name='Greek Yogurt Bowl',
            quantity=Decimal('1.00'),
            unit='serving',
            calories=Decimal('320.00'),
            protein=Decimal('24.00'),
            carbs=Decimal('28.00'),
            fat=Decimal('11.00'),
            notes=None,
        )
        return TodayMealsRead(
            date=selected_date,
            calories_total=Decimal('320.00'),
            protein_total=Decimal('24.00'),
            carbs_total=Decimal('28.00'),
            fat_total=Decimal('11.00'),
            meal_sections=[
                TodayMealSectionRead(
                    code=MealSectionCode.BREAKFAST,
                    title='Breakfast',
                    calories_total=Decimal('320.00'),
                    protein_total=Decimal('24.00'),
                    carbs_total=Decimal('28.00'),
                    fat_total=Decimal('11.00'),
                    entries=[breakfast_entry],
                ),
                TodayMealSectionRead(
                    code=MealSectionCode.LUNCH,
                    title='Lunch',
                    entries=[],
                ),
                TodayMealSectionRead(
                    code=MealSectionCode.DINNER,
                    title='Dinner',
                    entries=[],
                ),
                TodayMealSectionRead(
                    code=MealSectionCode.SNACKS,
                    title='Snacks',
                    entries=[],
                ),
            ],
        )


async def override_current_user():
    return SimpleNamespace(id=uuid4())


def override_meals_service() -> FakeMealsService:
    return FakeMealsService()


def test_meals_endpoint_returns_stable_day_sections() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_meals_service] = override_meals_service

    response = client.get('/api/v1/meals', params={'date': '2026-03-10'})

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['date'] == '2026-03-10'
    assert payload['calories_total'] in ('320.00', 320.0, 320)
    assert [section['code'] for section in payload['meal_sections']] == [
        'breakfast',
        'lunch',
        'dinner',
        'snacks',
    ]
    assert payload['meal_sections'][1]['entries'] == []