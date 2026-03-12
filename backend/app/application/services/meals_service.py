from datetime import date
from decimal import Decimal
from uuid import UUID

from app.domain.foods.models import Food
from app.domain.meals.models import Meal, MealEntry
from app.domain.meals.schemas import (
    DeleteResponse,
    MealEntryCreateRequest,
    MealEntryUpdateRequest,
    MealSectionCode,
    TodayMealEntryRead,
    TodayMealsRead,
    TodayMealSectionRead,
)
from app.infrastructure.persistence.repositories.foods_repository import FoodsRepository
from app.infrastructure.persistence.repositories.meals_repository import MealsRepository

_ZERO = Decimal('0.00')
_QUANTIZER = Decimal('0.01')
_SECTION_TITLES = {
    MealSectionCode.BREAKFAST: 'Breakfast',
    MealSectionCode.LUNCH: 'Lunch',
    MealSectionCode.DINNER: 'Dinner',
    MealSectionCode.SNACKS: 'Snacks',
}
_CALORIE_CODES = {'calorie', 'calories', 'energy', 'kcal'}
_PROTEIN_CODES = {'protein'}
_CARB_CODES = {'carb', 'carbs', 'carbohydrate', 'carbohydrates'}
_FAT_CODES = {'fat', 'fats', 'total_fat'}


class MealsService:
    def __init__(self, meals_repository: MealsRepository, foods_repository: FoodsRepository):
        self.meals_repository = meals_repository
        self.foods_repository = foods_repository

    @staticmethod
    def _quantize(value: Decimal) -> Decimal:
        return value.quantize(_QUANTIZER)

    @staticmethod
    def _normalize_code(code: str) -> str:
        return code.strip().lower()

    @staticmethod
    def _normalize_unit(unit: str | None, fallback: str | None = None) -> str:
        normalized = (unit or '').strip()
        if normalized:
            return normalized
        return (fallback or 'serving').strip()

    @staticmethod
    def _resolve_section_code(meal: Meal) -> MealSectionCode:
        normalized_name = meal.name.strip().lower()
        if 'breakfast' in normalized_name:
            return MealSectionCode.BREAKFAST
        if 'lunch' in normalized_name:
            return MealSectionCode.LUNCH
        if 'dinner' in normalized_name:
            return MealSectionCode.DINNER
        if normalized_name in {'snack', 'snacks'} or 'snack' in normalized_name:
            return MealSectionCode.SNACKS
        return MealSectionCode.SNACKS

    def _empty_sections(self) -> dict[MealSectionCode, TodayMealSectionRead]:
        return {
            code: TodayMealSectionRead(
                code=code,
                title=_SECTION_TITLES[code],
                calories_total=_ZERO,
                protein_total=_ZERO,
                carbs_total=_ZERO,
                fat_total=_ZERO,
                entries=[],
            )
            for code in MealSectionCode
        }

    def _extract_food_macros(self, food: Food) -> tuple[Decimal, Decimal, Decimal, Decimal]:
        calories = _ZERO
        protein = _ZERO
        carbs = _ZERO
        fat = _ZERO

        for nutrient in food.nutrients:
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

        return calories, protein, carbs, fat

    def _resolve_multiplier(self, food: Food, quantity: Decimal, unit: str) -> Decimal:
        if quantity <= 0:
            raise ValueError('invalid_quantity')

        default_amount = food.default_serving_amount or Decimal('1.00')
        if default_amount == 0:
            default_amount = Decimal('1.00')

        normalized_unit = unit.strip().lower()
        default_unit = (food.default_serving_unit or '').strip().lower()
        if default_unit and normalized_unit != default_unit:
            raise ValueError('unit_mismatch')

        return quantity / default_amount

    def _build_food_snapshot(
        self,
        food: Food,
        *,
        quantity: Decimal,
        unit: str,
    ) -> dict[str, Decimal | str]:
        normalized_unit = self._normalize_unit(unit, food.default_serving_unit)
        multiplier = self._resolve_multiplier(food, quantity, normalized_unit)
        calories, protein, carbs, fat = self._extract_food_macros(food)

        return {
            'food_name': food.name,
            'quantity': self._quantize(quantity),
            'unit': normalized_unit,
            'calories_total': self._quantize(calories * multiplier),
            'protein_total': self._quantize(protein * multiplier),
            'carbs_total': self._quantize(carbs * multiplier),
            'fat_total': self._quantize(fat * multiplier),
        }

    def _extract_entry_totals(self, entry: MealEntry) -> tuple[Decimal, Decimal, Decimal, Decimal]:
        if entry.food_name.strip():
            return (
                self._quantize(entry.calories_total),
                self._quantize(entry.protein_total),
                self._quantize(entry.carbs_total),
                self._quantize(entry.fat_total),
            )

        if entry.food is None:
            return _ZERO, _ZERO, _ZERO, _ZERO

        unit = self._normalize_unit(entry.unit, entry.food.default_serving_unit)
        multiplier = self._resolve_multiplier(entry.food, entry.quantity, unit)
        calories, protein, carbs, fat = self._extract_food_macros(entry.food)
        return (
            self._quantize(calories * multiplier),
            self._quantize(protein * multiplier),
            self._quantize(carbs * multiplier),
            self._quantize(fat * multiplier),
        )

    def _build_entry(self, entry: MealEntry) -> TodayMealEntryRead:
        calories, protein, carbs, fat = self._extract_entry_totals(entry)
        food_name = entry.food_name.strip()
        if not food_name:
            food_name = entry.food.name if entry.food is not None else 'Unlinked food'

        return TodayMealEntryRead(
            id=entry.id,
            meal_id=entry.meal_id,
            food_id=entry.food_id,
            food_name=food_name,
            quantity=self._quantize(entry.quantity),
            unit=entry.unit,
            calories=calories,
            protein=protein,
            carbs=carbs,
            fat=fat,
            notes=entry.notes,
        )

    async def get_day_meals(self, user_id: UUID, selected_date: date) -> TodayMealsRead:
        meals = await self.meals_repository.get_meals_for_user_on_date(user_id, selected_date)
        sections = self._empty_sections()

        for meal in meals:
            section = sections[self._resolve_section_code(meal)]
            for entry in sorted(meal.entries, key=lambda item: item.created_at):
                section_entry = self._build_entry(entry)
                section.entries.append(section_entry)
                section.calories_total = self._quantize(section.calories_total + section_entry.calories)
                section.protein_total = self._quantize(section.protein_total + section_entry.protein)
                section.carbs_total = self._quantize(section.carbs_total + section_entry.carbs)
                section.fat_total = self._quantize(section.fat_total + section_entry.fat)

        ordered_sections = [sections[code] for code in MealSectionCode]
        calories_total = sum((section.calories_total for section in ordered_sections), start=_ZERO)
        protein_total = sum((section.protein_total for section in ordered_sections), start=_ZERO)
        carbs_total = sum((section.carbs_total for section in ordered_sections), start=_ZERO)
        fat_total = sum((section.fat_total for section in ordered_sections), start=_ZERO)

        return TodayMealsRead(
            date=selected_date,
            calories_total=self._quantize(calories_total),
            protein_total=self._quantize(protein_total),
            carbs_total=self._quantize(carbs_total),
            fat_total=self._quantize(fat_total),
            meal_sections=ordered_sections,
        )

    async def create_meal_entry(
        self,
        user_id: UUID,
        payload: MealEntryCreateRequest,
    ) -> TodayMealEntryRead:
        food = await self.foods_repository.get_food(payload.food_id)
        if food is None:
            raise LookupError('food_not_found')

        meal = await self.meals_repository.get_or_create_meal_for_user_on_date_and_section(
            user_id=user_id,
            selected_date=payload.date,
            section_code=payload.meal_section,
        )
        snapshot = self._build_food_snapshot(
            food,
            quantity=payload.quantity,
            unit=payload.unit,
        )
        entry = self.meals_repository.create_meal_entry(
            meal_id=meal.id,
            food_id=food.id,
            food_name=snapshot['food_name'],
            quantity=snapshot['quantity'],
            unit=snapshot['unit'],
            calories_total=snapshot['calories_total'],
            protein_total=snapshot['protein_total'],
            carbs_total=snapshot['carbs_total'],
            fat_total=snapshot['fat_total'],
            notes=payload.notes,
        )
        await self.meals_repository.commit()

        created_entry = await self.meals_repository.get_meal_entry_for_user(entry.id, user_id)
        if created_entry is None:
            raise LookupError('meal_entry_not_found')
        return self._build_entry(created_entry)

    async def update_meal_entry(
        self,
        user_id: UUID,
        entry_id: UUID,
        payload: MealEntryUpdateRequest,
    ) -> TodayMealEntryRead:
        entry = await self.meals_repository.get_meal_entry_for_user(entry_id, user_id)
        if entry is None:
            raise LookupError('meal_entry_not_found')

        payload_data = payload.model_dump(exclude_unset=True)
        food = entry.food
        if 'food_id' in payload_data:
            if payload.food_id is None:
                raise ValueError('food_required')
            food = await self.foods_repository.get_food(payload.food_id)
            if food is None:
                raise LookupError('food_not_found')
            entry.food_id = food.id

        if food is None:
            raise LookupError('food_not_found')

        quantity = payload.quantity if 'quantity' in payload_data else entry.quantity
        unit = payload.unit if 'unit' in payload_data else entry.unit
        snapshot = self._build_food_snapshot(food, quantity=quantity, unit=unit)

        entry.food_name = snapshot['food_name']
        entry.quantity = snapshot['quantity']
        entry.unit = snapshot['unit']
        entry.calories_total = snapshot['calories_total']
        entry.protein_total = snapshot['protein_total']
        entry.carbs_total = snapshot['carbs_total']
        entry.fat_total = snapshot['fat_total']
        if 'notes' in payload_data:
            entry.notes = payload.notes

        await self.meals_repository.commit()
        updated_entry = await self.meals_repository.get_meal_entry_for_user(entry.id, user_id)
        if updated_entry is None:
            raise LookupError('meal_entry_not_found')
        return self._build_entry(updated_entry)

    async def delete_meal_entry(self, user_id: UUID, entry_id: UUID) -> DeleteResponse:
        entry = await self.meals_repository.get_meal_entry_for_user(entry_id, user_id)
        if entry is None:
            raise LookupError('meal_entry_not_found')

        await self.meals_repository.delete(entry)
        await self.meals_repository.commit()
        return DeleteResponse()

    async def list_meals_for_user(self, user_id: UUID) -> list[Meal]:
        return await self.meals_repository.list_meals_for_user(user_id)

    async def list_entries_for_meal(self, meal_id: UUID) -> list[MealEntry]:
        return await self.meals_repository.list_entries_for_meal(meal_id)

