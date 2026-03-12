from decimal import Decimal
from uuid import UUID

from pydantic import Field

from app.domain.shared.schemas import DomainSchema, TimestampedReadSchema


class FoodCreate(DomainSchema):
    name: str
    brand: str | None = None
    default_serving_amount: Decimal | None = None
    default_serving_unit: str | None = None
    source: str = 'internal'
    is_verified: bool = False


class FoodUpdate(DomainSchema):
    name: str | None = None
    brand: str | None = None
    default_serving_amount: Decimal | None = None
    default_serving_unit: str | None = None
    source: str | None = None
    is_verified: bool | None = None


class FoodRead(TimestampedReadSchema):
    name: str
    brand: str | None = None
    default_serving_amount: Decimal | None = None
    default_serving_unit: str | None = None
    source: str
    is_verified: bool


class FoodNutrientCreate(DomainSchema):
    food_id: UUID
    nutrient_code: str
    nutrient_name: str
    amount: Decimal
    unit: str
    display_order: int = 0


class FoodNutrientUpdate(DomainSchema):
    nutrient_name: str | None = None
    amount: Decimal | None = None
    unit: str | None = None
    display_order: int | None = None


class FoodNutrientRead(TimestampedReadSchema):
    food_id: UUID
    nutrient_code: str
    nutrient_name: str
    amount: Decimal
    unit: str
    display_order: int


class FoodSearchResultRead(DomainSchema):
    id: UUID
    name: str
    brand: str | None = None
    default_serving_amount: Decimal | None = None
    default_serving_unit: str | None = None
    is_verified: bool
    calories: Decimal = Decimal('0.00')
    protein: Decimal = Decimal('0.00')
    carbs: Decimal = Decimal('0.00')
    fat: Decimal = Decimal('0.00')


class FoodSearchResultsRead(DomainSchema):
    query: str
    items: list[FoodSearchResultRead] = Field(default_factory=list)


class FoodDetailRead(FoodRead):
    calories: Decimal = Decimal('0.00')
    protein: Decimal = Decimal('0.00')
    carbs: Decimal = Decimal('0.00')
    fat: Decimal = Decimal('0.00')
    nutrients: list[FoodNutrientRead] = Field(default_factory=list)
