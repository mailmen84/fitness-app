from datetime import date
from decimal import Decimal
from enum import StrEnum
from uuid import UUID

from pydantic import Field

from app.domain.meals.schemas import MealSectionCode
from app.domain.shared.schemas import DomainSchema


class NutritionRange(StrEnum):
    DAY = 'day'
    WEEK = 'week'
    MONTH = 'month'


class NutritionMetricType(StrEnum):
    CALORIES = 'calories'
    PROTEIN = 'protein'
    CARBS = 'carbs'
    FAT = 'fat'


class NutritionTargetsRead(DomainSchema):
    calories: Decimal | None = None
    protein: Decimal | None = None
    carbs: Decimal | None = None
    fat: Decimal | None = None


class NutritionCategoryRowRead(DomainSchema):
    code: NutritionMetricType
    title: str
    amount: Decimal = Decimal('0.00')
    unit: str
    target: Decimal | None = None
    progress_ratio: Decimal | None = None


class NutritionContributorRead(DomainSchema):
    entry_id: UUID
    meal_id: UUID
    meal_section: MealSectionCode
    food_name: str
    quantity: Decimal
    unit: str
    calories: Decimal = Decimal('0.00')
    protein: Decimal = Decimal('0.00')
    carbs: Decimal = Decimal('0.00')
    fat: Decimal = Decimal('0.00')


class NutritionOverviewRead(DomainSchema):
    range: NutritionRange
    anchor_date: date
    period_start: date
    period_end: date
    calories_total: Decimal = Decimal('0.00')
    protein_total: Decimal = Decimal('0.00')
    carbs_total: Decimal = Decimal('0.00')
    fat_total: Decimal = Decimal('0.00')
    targets: NutritionTargetsRead = Field(default_factory=NutritionTargetsRead)
    category_rows: list[NutritionCategoryRowRead] = Field(default_factory=list)
    top_contributors: list[NutritionContributorRead] = Field(default_factory=list)


class NutritionMacroContributorRead(DomainSchema):
    entry_id: UUID
    meal_id: UUID
    meal_section: MealSectionCode
    food_name: str
    quantity: Decimal
    unit: str
    value: Decimal = Decimal('0.00')
    share_ratio: Decimal | None = None


class NutritionMacroRead(DomainSchema):
    macro_type: NutritionMetricType
    range: NutritionRange
    anchor_date: date
    period_start: date
    period_end: date
    total: Decimal = Decimal('0.00')
    unit: str
    target: Decimal | None = None
    contributors: list[NutritionMacroContributorRead] = Field(default_factory=list)
