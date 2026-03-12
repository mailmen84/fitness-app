from datetime import date, datetime, time, timedelta, timezone
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import selectinload

from app.domain.foods.models import Food
from app.domain.meals.models import Meal, MealEntry
from app.domain.meals.schemas import MealSectionCode
from app.infrastructure.persistence.repositories.base_repository import BaseRepository

_SECTION_TITLES = {
    MealSectionCode.BREAKFAST: 'Breakfast',
    MealSectionCode.LUNCH: 'Lunch',
    MealSectionCode.DINNER: 'Dinner',
    MealSectionCode.SNACKS: 'Snacks',
}
_SECTION_TIMES = {
    MealSectionCode.BREAKFAST: time(hour=8, tzinfo=timezone.utc),
    MealSectionCode.LUNCH: time(hour=12, tzinfo=timezone.utc),
    MealSectionCode.DINNER: time(hour=18, tzinfo=timezone.utc),
    MealSectionCode.SNACKS: time(hour=15, tzinfo=timezone.utc),
}


class MealsRepository(BaseRepository):
    @staticmethod
    def _range_bounds(period_start: date, period_end: date) -> tuple[datetime, datetime]:
        range_start = datetime.combine(period_start, time.min, tzinfo=timezone.utc)
        range_end = datetime.combine(period_end + timedelta(days=1), time.min, tzinfo=timezone.utc)
        return range_start, range_end

    async def list_meals_for_user_between_dates(
        self,
        user_id: UUID,
        period_start: date,
        period_end: date,
        *,
        include_food_context: bool = False,
    ) -> list[Meal]:
        range_start, range_end = self._range_bounds(period_start, period_end)
        options = [selectinload(Meal.entries)]
        if include_food_context:
            options = [
                selectinload(Meal.entries)
                .selectinload(MealEntry.food)
                .selectinload(Food.nutrients)
            ]

        result = await self.session.execute(
            select(Meal)
            .options(*options)
            .where(
                Meal.user_id == user_id,
                Meal.occurred_at >= range_start,
                Meal.occurred_at < range_end,
            )
            .order_by(Meal.occurred_at.asc())
        )
        return list(result.scalars())

    async def get_meals_for_user_on_date(self, user_id: UUID, selected_date: date) -> list[Meal]:
        return await self.list_meals_for_user_between_dates(
            user_id=user_id,
            period_start=selected_date,
            period_end=selected_date,
            include_food_context=True,
        )

    async def get_meal_for_user_on_date_and_section(
        self,
        user_id: UUID,
        selected_date: date,
        section_code: MealSectionCode,
    ) -> Meal | None:
        day_start, day_end = self._range_bounds(selected_date, selected_date)
        result = await self.session.execute(
            select(Meal)
            .where(
                Meal.user_id == user_id,
                Meal.occurred_at >= day_start,
                Meal.occurred_at < day_end,
                func.lower(Meal.name) == _SECTION_TITLES[section_code].lower(),
            )
            .order_by(Meal.occurred_at.asc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    async def get_or_create_meal_for_user_on_date_and_section(
        self,
        user_id: UUID,
        selected_date: date,
        section_code: MealSectionCode,
    ) -> Meal:
        meal = await self.get_meal_for_user_on_date_and_section(
            user_id=user_id,
            selected_date=selected_date,
            section_code=section_code,
        )
        if meal is not None:
            return meal

        meal = Meal(
            user_id=user_id,
            name=_SECTION_TITLES[section_code],
            occurred_at=datetime.combine(selected_date, _SECTION_TIMES[section_code]),
        )
        self.add(meal)
        await self.flush()
        return meal

    async def get_meal_entry_for_user(self, entry_id: UUID, user_id: UUID) -> MealEntry | None:
        result = await self.session.execute(
            select(MealEntry)
            .join(Meal, MealEntry.meal_id == Meal.id)
            .options(
                selectinload(MealEntry.meal),
                selectinload(MealEntry.food).selectinload(Food.nutrients),
            )
            .where(
                MealEntry.id == entry_id,
                Meal.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    def create_meal_entry(
        self,
        *,
        meal_id: UUID,
        food_id: UUID | None,
        food_name: str,
        quantity,
        unit: str,
        calories_total,
        protein_total,
        carbs_total,
        fat_total,
        notes: str | None,
    ) -> MealEntry:
        entry = MealEntry(
            meal_id=meal_id,
            food_id=food_id,
            food_name=food_name,
            quantity=quantity,
            unit=unit,
            calories_total=calories_total,
            protein_total=protein_total,
            carbs_total=carbs_total,
            fat_total=fat_total,
            notes=notes,
        )
        self.add(entry)
        return entry

    async def list_meals_for_user(self, user_id: UUID) -> list[Meal]:
        result = await self.session.scalars(
            select(Meal).where(Meal.user_id == user_id).order_by(Meal.occurred_at.desc())
        )
        return list(result)

    async def list_entries_for_meal(self, meal_id: UUID) -> list[MealEntry]:
        result = await self.session.scalars(
            select(MealEntry)
            .options(selectinload(MealEntry.food))
            .where(MealEntry.meal_id == meal_id)
            .order_by(MealEntry.created_at.asc())
        )
        return list(result)
