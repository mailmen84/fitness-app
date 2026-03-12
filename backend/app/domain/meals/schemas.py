from datetime import date, datetime
from decimal import Decimal
from enum import StrEnum
from uuid import UUID

from pydantic import Field

from app.domain.shared.schemas import DomainSchema, TimestampedReadSchema


class MealCreate(DomainSchema):
    user_id: UUID
    name: str
    occurred_at: datetime
    notes: str | None = None


class MealUpdate(DomainSchema):
    name: str | None = None
    occurred_at: datetime | None = None
    notes: str | None = None


class MealRead(TimestampedReadSchema):
    user_id: UUID
    name: str
    occurred_at: datetime
    notes: str | None = None


class MealEntryCreate(DomainSchema):
    meal_id: UUID
    food_id: UUID | None = None
    food_name: str = ''
    quantity: Decimal
    unit: str
    calories_total: Decimal = Decimal('0.00')
    protein_total: Decimal = Decimal('0.00')
    carbs_total: Decimal = Decimal('0.00')
    fat_total: Decimal = Decimal('0.00')
    notes: str | None = None


class MealEntryUpdate(DomainSchema):
    food_id: UUID | None = None
    food_name: str | None = None
    quantity: Decimal | None = None
    unit: str | None = None
    calories_total: Decimal | None = None
    protein_total: Decimal | None = None
    carbs_total: Decimal | None = None
    fat_total: Decimal | None = None
    notes: str | None = None


class MealEntryRead(TimestampedReadSchema):
    meal_id: UUID
    food_id: UUID | None = None
    food_name: str
    quantity: Decimal
    unit: str
    calories_total: Decimal = Decimal('0.00')
    protein_total: Decimal = Decimal('0.00')
    carbs_total: Decimal = Decimal('0.00')
    fat_total: Decimal = Decimal('0.00')
    notes: str | None = None


class MealSectionCode(StrEnum):
    BREAKFAST = 'breakfast'
    LUNCH = 'lunch'
    DINNER = 'dinner'
    SNACKS = 'snacks'


class MealEntryCreateRequest(DomainSchema):
    date: date
    meal_section: MealSectionCode
    food_id: UUID
    quantity: Decimal = Field(gt=0)
    unit: str
    notes: str | None = None


class MealEntryUpdateRequest(DomainSchema):
    food_id: UUID | None = None
    quantity: Decimal | None = Field(default=None, gt=0)
    unit: str | None = None
    notes: str | None = None


class DeleteResponse(DomainSchema):
    ok: bool = True
    detail: str = 'Meal entry deleted.'


class TodayMealEntryRead(DomainSchema):
    id: UUID
    meal_id: UUID
    food_id: UUID | None = None
    food_name: str
    quantity: Decimal
    unit: str
    calories: Decimal = Decimal('0.00')
    protein: Decimal = Decimal('0.00')
    carbs: Decimal = Decimal('0.00')
    fat: Decimal = Decimal('0.00')
    notes: str | None = None


class TodayMealSectionRead(DomainSchema):
    code: MealSectionCode
    title: str
    calories_total: Decimal = Decimal('0.00')
    protein_total: Decimal = Decimal('0.00')
    carbs_total: Decimal = Decimal('0.00')
    fat_total: Decimal = Decimal('0.00')
    entries: list[TodayMealEntryRead] = Field(default_factory=list)


class TodayMealsRead(DomainSchema):
    date: date
    calories_total: Decimal = Decimal('0.00')
    protein_total: Decimal = Decimal('0.00')
    carbs_total: Decimal = Decimal('0.00')
    fat_total: Decimal = Decimal('0.00')
    meal_sections: list[TodayMealSectionRead] = Field(default_factory=list)
