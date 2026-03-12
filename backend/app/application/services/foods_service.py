from decimal import Decimal
from uuid import UUID

from app.domain.foods.models import Food, FoodNutrient
from app.domain.foods.schemas import FoodDetailRead, FoodNutrientRead, FoodSearchResultRead, FoodSearchResultsRead
from app.infrastructure.persistence.repositories.foods_repository import FoodsRepository

_ZERO = Decimal('0.00')
_QUANTIZER = Decimal('0.01')
_CALORIE_CODES = {'calorie', 'calories', 'energy', 'kcal'}
_PROTEIN_CODES = {'protein'}
_CARB_CODES = {'carb', 'carbs', 'carbohydrate', 'carbohydrates'}
_FAT_CODES = {'fat', 'fats', 'total_fat'}
_SEED_FOODS = (
    {
        'name': 'Greek Yogurt',
        'brand': 'Demo Pantry',
        'amount': '170.00',
        'unit': 'g',
        'nutrients': (
            ('calories', 'Calories', '100.00', 'kcal', 10),
            ('protein', 'Protein', '17.00', 'g', 20),
            ('carbs', 'Carbs', '6.00', 'g', 30),
            ('fat', 'Fat', '0.00', 'g', 40),
        ),
    },
    {
        'name': 'Chicken Breast',
        'brand': 'Demo Pantry',
        'amount': '120.00',
        'unit': 'g',
        'nutrients': (
            ('calories', 'Calories', '198.00', 'kcal', 10),
            ('protein', 'Protein', '37.00', 'g', 20),
            ('carbs', 'Carbs', '0.00', 'g', 30),
            ('fat', 'Fat', '4.00', 'g', 40),
        ),
    },
    {
        'name': 'White Rice',
        'brand': 'Demo Pantry',
        'amount': '150.00',
        'unit': 'g',
        'nutrients': (
            ('calories', 'Calories', '206.00', 'kcal', 10),
            ('protein', 'Protein', '4.00', 'g', 20),
            ('carbs', 'Carbs', '45.00', 'g', 30),
            ('fat', 'Fat', '0.40', 'g', 40),
        ),
    },
    {
        'name': 'Salmon Fillet',
        'brand': 'Demo Pantry',
        'amount': '120.00',
        'unit': 'g',
        'nutrients': (
            ('calories', 'Calories', '245.00', 'kcal', 10),
            ('protein', 'Protein', '26.00', 'g', 20),
            ('carbs', 'Carbs', '0.00', 'g', 30),
            ('fat', 'Fat', '15.00', 'g', 40),
        ),
    },
    {
        'name': 'Banana',
        'brand': None,
        'amount': '118.00',
        'unit': 'g',
        'nutrients': (
            ('calories', 'Calories', '105.00', 'kcal', 10),
            ('protein', 'Protein', '1.30', 'g', 20),
            ('carbs', 'Carbs', '27.00', 'g', 30),
            ('fat', 'Fat', '0.40', 'g', 40),
        ),
    },
    {
        'name': 'Oats',
        'brand': 'Demo Pantry',
        'amount': '40.00',
        'unit': 'g',
        'nutrients': (
            ('calories', 'Calories', '154.00', 'kcal', 10),
            ('protein', 'Protein', '5.00', 'g', 20),
            ('carbs', 'Carbs', '27.00', 'g', 30),
            ('fat', 'Fat', '3.00', 'g', 40),
        ),
    },
    {
        'name': 'Protein Bar',
        'brand': 'Demo Pantry',
        'amount': '1.00',
        'unit': 'bar',
        'nutrients': (
            ('calories', 'Calories', '220.00', 'kcal', 10),
            ('protein', 'Protein', '20.00', 'g', 20),
            ('carbs', 'Carbs', '18.00', 'g', 30),
            ('fat', 'Fat', '7.00', 'g', 40),
        ),
    },
    {
        'name': 'Whole Eggs',
        'brand': None,
        'amount': '2.00',
        'unit': 'piece',
        'nutrients': (
            ('calories', 'Calories', '144.00', 'kcal', 10),
            ('protein', 'Protein', '12.60', 'g', 20),
            ('carbs', 'Carbs', '0.80', 'g', 30),
            ('fat', 'Fat', '9.60', 'g', 40),
        ),
    },
    {
        'name': 'Milk',
        'brand': 'Demo Pantry',
        'amount': '250.00',
        'unit': 'ml',
        'nutrients': (
            ('calories', 'Calories', '122.00', 'kcal', 10),
            ('protein', 'Protein', '8.00', 'g', 20),
            ('carbs', 'Carbs', '12.00', 'g', 30),
            ('fat', 'Fat', '4.80', 'g', 40),
        ),
    },
    {
        'name': 'Almonds',
        'brand': None,
        'amount': '28.00',
        'unit': 'g',
        'nutrients': (
            ('calories', 'Calories', '164.00', 'kcal', 10),
            ('protein', 'Protein', '6.00', 'g', 20),
            ('carbs', 'Carbs', '6.00', 'g', 30),
            ('fat', 'Fat', '14.00', 'g', 40),
        ),
    },
)


class FoodsService:
    def __init__(self, foods_repository: FoodsRepository):
        self.foods_repository = foods_repository

    @staticmethod
    def _quantize(value: Decimal) -> Decimal:
        return value.quantize(_QUANTIZER)

    @staticmethod
    def _normalize_code(code: str) -> str:
        return code.strip().lower()

    def _extract_macros(self, nutrients: list[FoodNutrient]) -> tuple[Decimal, Decimal, Decimal, Decimal]:
        calories = _ZERO
        protein = _ZERO
        carbs = _ZERO
        fat = _ZERO

        for nutrient in nutrients:
            normalized_code = self._normalize_code(nutrient.nutrient_code)
            amount = nutrient.amount
            if normalized_code in _CALORIE_CODES:
                calories += amount
            elif normalized_code in _PROTEIN_CODES:
                protein += amount
            elif normalized_code in _CARB_CODES:
                carbs += amount
            elif normalized_code in _FAT_CODES:
                fat += amount

        return (
            self._quantize(calories),
            self._quantize(protein),
            self._quantize(carbs),
            self._quantize(fat),
        )

    def _to_search_result(self, food: Food) -> FoodSearchResultRead:
        calories, protein, carbs, fat = self._extract_macros(food.nutrients)
        return FoodSearchResultRead(
            id=food.id,
            name=food.name,
            brand=food.brand,
            default_serving_amount=food.default_serving_amount,
            default_serving_unit=food.default_serving_unit,
            is_verified=food.is_verified,
            calories=calories,
            protein=protein,
            carbs=carbs,
            fat=fat,
        )

    def _to_food_detail(self, food: Food) -> FoodDetailRead:
        calories, protein, carbs, fat = self._extract_macros(food.nutrients)
        nutrients = [
            FoodNutrientRead.model_validate(nutrient)
            for nutrient in sorted(food.nutrients, key=lambda item: (item.display_order, item.nutrient_name))
        ]
        return FoodDetailRead(
            id=food.id,
            created_at=food.created_at,
            updated_at=food.updated_at,
            name=food.name,
            brand=food.brand,
            default_serving_amount=food.default_serving_amount,
            default_serving_unit=food.default_serving_unit,
            source=food.source,
            is_verified=food.is_verified,
            calories=calories,
            protein=protein,
            carbs=carbs,
            fat=fat,
            nutrients=nutrients,
        )

    async def ensure_development_foods_seeded(self) -> None:
        if await self.foods_repository.has_foods():
            return

        for item in _SEED_FOODS:
            food = self.foods_repository.create_food(
                name=item['name'],
                brand=item['brand'],
                default_serving_amount=Decimal(item['amount']),
                default_serving_unit=item['unit'],
                source='development_seed',
                is_verified=True,
            )
            await self.foods_repository.flush()
            for nutrient_code, nutrient_name, amount, unit, display_order in item['nutrients']:
                self.foods_repository.create_food_nutrient(
                    food_id=food.id,
                    nutrient_code=nutrient_code,
                    nutrient_name=nutrient_name,
                    amount=Decimal(amount),
                    unit=unit,
                    display_order=display_order,
                )

        await self.foods_repository.commit()

    async def search_foods(self, query: str, limit: int = 20) -> FoodSearchResultsRead:
        normalized_query = query.strip()
        if not normalized_query:
            return FoodSearchResultsRead(query='', items=[])

        await self.ensure_development_foods_seeded()
        foods = await self.foods_repository.search_by_name(query=normalized_query, limit=limit)
        return FoodSearchResultsRead(
            query=normalized_query,
            items=[self._to_search_result(food) for food in foods],
        )

    async def get_food_detail(self, food_id: UUID) -> FoodDetailRead | None:
        await self.ensure_development_foods_seeded()
        food = await self.foods_repository.get_food(food_id)
        if food is None:
            return None
        return self._to_food_detail(food)

