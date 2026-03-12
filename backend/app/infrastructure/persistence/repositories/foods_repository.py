from uuid import UUID

from sqlalchemy import case, func, select
from sqlalchemy.orm import selectinload

from app.domain.foods.models import Food, FoodNutrient
from app.infrastructure.persistence.repositories.base_repository import BaseRepository


class FoodsRepository(BaseRepository):
    async def get_food(self, food_id: UUID) -> Food | None:
        result = await self.session.execute(
            select(Food)
            .options(selectinload(Food.nutrients))
            .where(Food.id == food_id)
        )
        return result.scalar_one_or_none()

    async def search_by_name(self, query: str, limit: int = 20) -> list[Food]:
        normalized_query = query.strip()
        if not normalized_query:
            return []

        lowered_query = normalized_query.lower()
        ranking = case(
            (func.lower(Food.name) == lowered_query, 0),
            (func.lower(Food.name).like(f'{lowered_query}%'), 1),
            else_=2,
        )
        result = await self.session.scalars(
            select(Food)
            .options(selectinload(Food.nutrients))
            .where(Food.name.ilike(f'%{normalized_query}%'))
            .order_by(ranking, Food.name.asc())
            .limit(limit)
        )
        return list(result)

    async def has_foods(self) -> bool:
        count = await self.session.scalar(select(func.count(Food.id)))
        return bool(count)

    def create_food(
        self,
        *,
        name: str,
        brand: str | None,
        default_serving_amount,
        default_serving_unit: str | None,
        source: str,
        is_verified: bool,
    ) -> Food:
        food = Food(
            name=name,
            brand=brand,
            default_serving_amount=default_serving_amount,
            default_serving_unit=default_serving_unit,
            source=source,
            is_verified=is_verified,
        )
        self.add(food)
        return food

    def create_food_nutrient(
        self,
        *,
        food_id: UUID,
        nutrient_code: str,
        nutrient_name: str,
        amount,
        unit: str,
        display_order: int,
    ) -> FoodNutrient:
        nutrient = FoodNutrient(
            food_id=food_id,
            nutrient_code=nutrient_code,
            nutrient_name=nutrient_name,
            amount=amount,
            unit=unit,
            display_order=display_order,
        )
        self.add(nutrient)
        return nutrient
