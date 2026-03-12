from datetime import date
from decimal import Decimal
from types import SimpleNamespace
from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import get_current_user, get_nutrition_service
from app.domain.meals.schemas import MealSectionCode
from app.domain.nutrition.schemas import (
    NutritionCategoryRowRead,
    NutritionContributorRead,
    NutritionMacroContributorRead,
    NutritionMacroRead,
    NutritionMetricType,
    NutritionOverviewRead,
    NutritionRange,
    NutritionTargetsRead,
)
from app.main import app

client = TestClient(app)


class FakeNutritionService:
    async def get_overview(self, user_id, *, range_type: NutritionRange, anchor_date: date):  # noqa: ANN001
        return NutritionOverviewRead(
            range=range_type,
            anchor_date=anchor_date,
            period_start=anchor_date,
            period_end=anchor_date,
            calories_total=Decimal('1820.00'),
            protein_total=Decimal('132.00'),
            carbs_total=Decimal('168.00'),
            fat_total=Decimal('58.00'),
            targets=NutritionTargetsRead(
                calories=Decimal('2100.00'),
                protein=Decimal('140.00'),
            ),
            category_rows=[
                NutritionCategoryRowRead(
                    code=NutritionMetricType.CALORIES,
                    title='Calories',
                    amount=Decimal('1820.00'),
                    unit='kcal',
                    target=Decimal('2100.00'),
                    progress_ratio=Decimal('0.8667'),
                ),
                NutritionCategoryRowRead(
                    code=NutritionMetricType.PROTEIN,
                    title='Protein',
                    amount=Decimal('132.00'),
                    unit='g',
                    target=Decimal('140.00'),
                    progress_ratio=Decimal('0.9429'),
                ),
            ],
            top_contributors=[
                NutritionContributorRead(
                    entry_id=uuid4(),
                    meal_id=uuid4(),
                    meal_section=MealSectionCode.LUNCH,
                    food_name='Chicken rice bowl',
                    quantity=Decimal('1.00'),
                    unit='serving',
                    calories=Decimal('520.00'),
                    protein=Decimal('38.00'),
                    carbs=Decimal('42.00'),
                    fat=Decimal('18.00'),
                )
            ],
        )

    async def get_macro_detail(
        self,
        user_id,  # noqa: ANN001
        *,
        macro_type: NutritionMetricType,
        range_type: NutritionRange,
        anchor_date: date,
    ) -> NutritionMacroRead:
        return NutritionMacroRead(
            macro_type=macro_type,
            range=range_type,
            anchor_date=anchor_date,
            period_start=anchor_date,
            period_end=anchor_date,
            total=Decimal('132.00'),
            unit='g',
            target=Decimal('140.00'),
            contributors=[
                NutritionMacroContributorRead(
                    entry_id=uuid4(),
                    meal_id=uuid4(),
                    meal_section=MealSectionCode.LUNCH,
                    food_name='Chicken rice bowl',
                    quantity=Decimal('1.00'),
                    unit='serving',
                    value=Decimal('38.00'),
                    share_ratio=Decimal('0.2879'),
                )
            ],
        )


async def override_current_user():
    return SimpleNamespace(id=uuid4())


def override_nutrition_service() -> FakeNutritionService:
    return FakeNutritionService()


def test_nutrition_overview_endpoint_returns_stable_shape() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_nutrition_service] = override_nutrition_service

    response = client.get(
        '/api/v1/nutrition/overview',
        params={'range': 'day', 'date': '2026-03-11'},
    )

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['range'] == 'day'
    assert payload['anchor_date'] == '2026-03-11'
    assert payload['category_rows'][0]['code'] == 'calories'
    assert payload['top_contributors'][0]['meal_section'] == 'lunch'


def test_nutrition_macro_endpoint_returns_stable_shape() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_nutrition_service] = override_nutrition_service

    response = client.get(
        '/api/v1/nutrition/macro/protein',
        params={'range': 'day', 'date': '2026-03-11'},
    )

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['macro_type'] == 'protein'
    assert payload['total'] in ('132.00', 132.0, 132)
    assert payload['contributors'][0]['food_name'] == 'Chicken rice bowl'
