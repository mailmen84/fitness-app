from decimal import Decimal
from uuid import UUID

from pydantic import Field

from app.domain.shared.schemas import DomainSchema, TimestampedReadSchema


class FoodCreate(DomainSchema):
    name: str
    brand: str | None = None
    barcode: str | None = None
    default_serving_amount: Decimal | None = None
    default_serving_unit: str | None = None
    source: str = 'internal'
    is_verified: bool = False


class FoodUpdate(DomainSchema):
    name: str | None = None
    brand: str | None = None
    barcode: str | None = None
    default_serving_amount: Decimal | None = None
    default_serving_unit: str | None = None
    source: str | None = None
    is_verified: bool | None = None


class FoodRead(TimestampedReadSchema):
    name: str
    brand: str | None = None
    barcode: str | None = None
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
    barcode: str | None = None
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


# --- Barcode + create flow schemas ---

class FoodCreateNutrientPayload(DomainSchema):
    """Single nutrient row when creating a food from the client."""

    code: str = Field(min_length=1, max_length=64)
    name: str = Field(min_length=1, max_length=120)
    amount: Decimal = Field(ge=0)
    unit: str = Field(min_length=1, max_length=32)
    display_order: int = 0


class FoodCreateRequest(DomainSchema):
    """Payload sent by the client when creating a food (custom or from OFF)."""

    name: str = Field(min_length=1, max_length=160)
    brand: str | None = Field(default=None, max_length=160)
    barcode: str | None = Field(default=None, max_length=32)
    default_serving_amount: Decimal | None = Field(default=None, gt=0)
    default_serving_unit: str | None = Field(default=None, max_length=32)
    source: str = Field(default='user', max_length=32)
    calories: Decimal = Field(ge=0)
    protein: Decimal = Field(ge=0)
    carbs: Decimal = Field(ge=0)
    fat: Decimal = Field(ge=0)
    extra_nutrients: list[FoodCreateNutrientPayload] = Field(default_factory=list)


class OpenFoodFactsLookup(DomainSchema):
    """Draft returned by the OFF lookup endpoint, ready for review/edit on the client.

    `is_complete` is True when calories, protein, carbs, and fat are all known.
    Missing fields come back as None and the UI flags them.
    """

    barcode: str
    found: bool
    is_complete: bool = False
    name: str | None = None
    brand: str | None = None
    default_serving_amount: Decimal | None = None
    default_serving_unit: str | None = None
    calories: Decimal | None = None
    protein: Decimal | None = None
    carbs: Decimal | None = None
    fat: Decimal | None = None
    image_url: str | None = None
    source_url: str | None = None
