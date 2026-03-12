from calendar import monthrange
from datetime import date, timedelta
from decimal import Decimal
from uuid import UUID

from app.domain.goals.models import Goal
from app.domain.meals.models import Meal, MealEntry
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
from app.domain.preferences.models import Preference
from app.infrastructure.persistence.repositories.goals_repository import GoalsRepository
from app.infrastructure.persistence.repositories.meals_repository import MealsRepository
from app.infrastructure.persistence.repositories.preferences_repository import PreferencesRepository

_ZERO = Decimal('0.00')
_AMOUNT_QUANTIZER = Decimal('0.01')
_RATIO_QUANTIZER = Decimal('0.0001')
_METRIC_UNITS = {
    NutritionMetricType.CALORIES: 'kcal',
    NutritionMetricType.PROTEIN: 'g',
    NutritionMetricType.CARBS: 'g',
    NutritionMetricType.FAT: 'g',
}
_METRIC_TITLES = {
    NutritionMetricType.CALORIES: 'Calories',
    NutritionMetricType.PROTEIN: 'Protein',
    NutritionMetricType.CARBS: 'Carbs',
    NutritionMetricType.FAT: 'Fat',
}


class NutritionService:
    def __init__(
        self,
        meals_repository: MealsRepository,
        preferences_repository: PreferencesRepository,
        goals_repository: GoalsRepository,
    ):
        self.meals_repository = meals_repository
        self.preferences_repository = preferences_repository
        self.goals_repository = goals_repository

    @staticmethod
    def _quantize_amount(value: Decimal | None) -> Decimal | None:
        if value is None:
            return None
        return value.quantize(_AMOUNT_QUANTIZER)

    @staticmethod
    def _quantize_ratio(value: Decimal | None) -> Decimal | None:
        if value is None:
            return None
        return value.quantize(_RATIO_QUANTIZER)

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

    @staticmethod
    def _coalesce(value: Decimal | None) -> Decimal:
        return value if value is not None else _ZERO

    @staticmethod
    def _days_in_period(period_start: date, period_end: date) -> int:
        return (period_end - period_start).days + 1

    @staticmethod
    def _metric_value(entry: MealEntry, metric_type: NutritionMetricType) -> Decimal:
        if metric_type == NutritionMetricType.CALORIES:
            return entry.calories_total
        if metric_type == NutritionMetricType.PROTEIN:
            return entry.protein_total
        if metric_type == NutritionMetricType.CARBS:
            return entry.carbs_total
        return entry.fat_total

    def _resolve_period(
        self,
        anchor_date: date,
        range_type: NutritionRange,
        preference: Preference | None,
    ) -> tuple[date, date]:
        normalized_anchor = anchor_date
        if range_type == NutritionRange.DAY:
            return normalized_anchor, normalized_anchor

        if range_type == NutritionRange.WEEK:
            week_starts_on = (preference.week_starts_on if preference is not None else 'monday').lower()
            if week_starts_on == 'sunday':
                offset = (normalized_anchor.weekday() + 1) % 7
            else:
                offset = normalized_anchor.weekday()
            period_start = normalized_anchor - timedelta(days=offset)
            return period_start, period_start + timedelta(days=6)

        days_in_month = monthrange(normalized_anchor.year, normalized_anchor.month)[1]
        period_start = normalized_anchor.replace(day=1)
        period_end = normalized_anchor.replace(day=days_in_month)
        return period_start, period_end

    def _nutrition_target_from_goal(
        self,
        goal: Goal | None,
        day_count: int,
    ) -> NutritionTargetsRead:
        targets = NutritionTargetsRead()
        if goal is None or goal.target_value is None:
            return targets

        normalized_code = goal.code.strip().lower()
        normalized_title = goal.title.strip().lower()
        normalized_unit = (goal.target_unit or '').strip().lower()
        scaled_target = self._quantize_amount(goal.target_value * Decimal(day_count))

        if (
            'calorie' in normalized_code
            or 'energy' in normalized_code
            or 'calorie' in normalized_title
            or normalized_unit in {'kcal', 'calorie', 'calories'}
        ):
            targets.calories = scaled_target
        elif 'protein' in normalized_code or 'protein' in normalized_title:
            targets.protein = scaled_target
        elif (
            'carb' in normalized_code
            or 'carb' in normalized_title
            or 'carbohydrate' in normalized_code
            or 'carbohydrate' in normalized_title
        ):
            targets.carbs = scaled_target
        elif 'fat' in normalized_code or 'fat' in normalized_title:
            targets.fat = scaled_target

        return targets

    def _resolve_targets(
        self,
        day_count: int,
        preference: Preference | None,
        goal: Goal | None,
    ) -> NutritionTargetsRead:
        preference_targets = NutritionTargetsRead(
            calories=self._quantize_amount(
                preference.daily_calorie_target * Decimal(day_count)
                if preference is not None and preference.daily_calorie_target is not None
                else None
            ),
            protein=self._quantize_amount(
                preference.daily_protein_target * Decimal(day_count)
                if preference is not None and preference.daily_protein_target is not None
                else None
            ),
        )
        goal_targets = self._nutrition_target_from_goal(goal, day_count)

        return NutritionTargetsRead(
            calories=goal_targets.calories or preference_targets.calories,
            protein=goal_targets.protein or preference_targets.protein,
            carbs=goal_targets.carbs or preference_targets.carbs,
            fat=goal_targets.fat or preference_targets.fat,
        )

    def _build_contributor(self, meal: Meal, entry: MealEntry) -> NutritionContributorRead:
        return NutritionContributorRead(
            entry_id=entry.id,
            meal_id=entry.meal_id,
            meal_section=self._resolve_section_code(meal),
            food_name=entry.food_name or 'Unlinked food',
            quantity=self._quantize_amount(entry.quantity) or _ZERO,
            unit=entry.unit,
            calories=self._quantize_amount(entry.calories_total) or _ZERO,
            protein=self._quantize_amount(entry.protein_total) or _ZERO,
            carbs=self._quantize_amount(entry.carbs_total) or _ZERO,
            fat=self._quantize_amount(entry.fat_total) or _ZERO,
        )

    def _iter_contributors(self, meals: list[Meal]) -> list[NutritionContributorRead]:
        contributors: list[NutritionContributorRead] = []
        for meal in meals:
            for entry in meal.entries:
                contributors.append(self._build_contributor(meal, entry))
        return contributors

    def _build_category_rows(
        self,
        *,
        calories_total: Decimal,
        protein_total: Decimal,
        carbs_total: Decimal,
        fat_total: Decimal,
        targets: NutritionTargetsRead,
    ) -> list[NutritionCategoryRowRead]:
        amounts = {
            NutritionMetricType.CALORIES: calories_total,
            NutritionMetricType.PROTEIN: protein_total,
            NutritionMetricType.CARBS: carbs_total,
            NutritionMetricType.FAT: fat_total,
        }
        target_map = {
            NutritionMetricType.CALORIES: targets.calories,
            NutritionMetricType.PROTEIN: targets.protein,
            NutritionMetricType.CARBS: targets.carbs,
            NutritionMetricType.FAT: targets.fat,
        }
        rows: list[NutritionCategoryRowRead] = []
        for metric_type, amount in amounts.items():
            target = target_map[metric_type]
            progress_ratio = None
            if target is not None and target > 0:
                progress_ratio = self._quantize_ratio(amount / target)
            rows.append(
                NutritionCategoryRowRead(
                    code=metric_type,
                    title=_METRIC_TITLES[metric_type],
                    amount=self._quantize_amount(amount) or _ZERO,
                    unit=_METRIC_UNITS[metric_type],
                    target=target,
                    progress_ratio=progress_ratio,
                )
            )
        return rows

    async def get_overview(
        self,
        user_id: UUID,
        *,
        range_type: NutritionRange,
        anchor_date: date,
    ) -> NutritionOverviewRead:
        preference = await self.preferences_repository.get_for_user(user_id)
        goal = await self.goals_repository.get_current_for_user(user_id)
        period_start, period_end = self._resolve_period(anchor_date, range_type, preference)
        meals = await self.meals_repository.list_meals_for_user_between_dates(
            user_id=user_id,
            period_start=period_start,
            period_end=period_end,
            include_food_context=False,
        )

        calories_total = _ZERO
        protein_total = _ZERO
        carbs_total = _ZERO
        fat_total = _ZERO
        for meal in meals:
            for entry in meal.entries:
                calories_total += self._coalesce(entry.calories_total)
                protein_total += self._coalesce(entry.protein_total)
                carbs_total += self._coalesce(entry.carbs_total)
                fat_total += self._coalesce(entry.fat_total)

        calories_total = self._quantize_amount(calories_total) or _ZERO
        protein_total = self._quantize_amount(protein_total) or _ZERO
        carbs_total = self._quantize_amount(carbs_total) or _ZERO
        fat_total = self._quantize_amount(fat_total) or _ZERO

        day_count = self._days_in_period(period_start, period_end)
        targets = self._resolve_targets(day_count, preference, goal)
        contributors = self._iter_contributors(meals)
        top_contributors = sorted(
            contributors,
            key=lambda item: (item.calories, item.protein, item.food_name),
            reverse=True,
        )[:5]

        return NutritionOverviewRead(
            range=range_type,
            anchor_date=anchor_date,
            period_start=period_start,
            period_end=period_end,
            calories_total=calories_total,
            protein_total=protein_total,
            carbs_total=carbs_total,
            fat_total=fat_total,
            targets=targets,
            category_rows=self._build_category_rows(
                calories_total=calories_total,
                protein_total=protein_total,
                carbs_total=carbs_total,
                fat_total=fat_total,
                targets=targets,
            ),
            top_contributors=top_contributors,
        )

    async def get_macro_detail(
        self,
        user_id: UUID,
        *,
        macro_type: NutritionMetricType,
        range_type: NutritionRange,
        anchor_date: date,
    ) -> NutritionMacroRead:
        preference = await self.preferences_repository.get_for_user(user_id)
        goal = await self.goals_repository.get_current_for_user(user_id)
        period_start, period_end = self._resolve_period(anchor_date, range_type, preference)
        meals = await self.meals_repository.list_meals_for_user_between_dates(
            user_id=user_id,
            period_start=period_start,
            period_end=period_end,
            include_food_context=False,
        )
        day_count = self._days_in_period(period_start, period_end)
        targets = self._resolve_targets(day_count, preference, goal)

        raw_contributors: list[NutritionMacroContributorRead] = []
        total = _ZERO
        for meal in meals:
            section_code = self._resolve_section_code(meal)
            for entry in meal.entries:
                value = self._quantize_amount(self._metric_value(entry, macro_type)) or _ZERO
                total += value
                raw_contributors.append(
                    NutritionMacroContributorRead(
                        entry_id=entry.id,
                        meal_id=entry.meal_id,
                        meal_section=section_code,
                        food_name=entry.food_name or 'Unlinked food',
                        quantity=self._quantize_amount(entry.quantity) or _ZERO,
                        unit=entry.unit,
                        value=value,
                        share_ratio=None,
                    )
                )

        total = self._quantize_amount(total) or _ZERO
        contributors = sorted(
            raw_contributors,
            key=lambda item: (item.value, item.food_name),
            reverse=True,
        )[:8]

        if total > 0:
            contributors = [
                contributor.model_copy(
                    update={
                        'share_ratio': self._quantize_ratio(contributor.value / total),
                    }
                )
                for contributor in contributors
            ]

        target_map = {
            NutritionMetricType.CALORIES: targets.calories,
            NutritionMetricType.PROTEIN: targets.protein,
            NutritionMetricType.CARBS: targets.carbs,
            NutritionMetricType.FAT: targets.fat,
        }

        return NutritionMacroRead(
            macro_type=macro_type,
            range=range_type,
            anchor_date=anchor_date,
            period_start=period_start,
            period_end=period_end,
            total=total,
            unit=_METRIC_UNITS[macro_type],
            target=target_map[macro_type],
            contributors=contributors,
        )
