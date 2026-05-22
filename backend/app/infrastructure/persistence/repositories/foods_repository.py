from uuid import UUID

from sqlalchemy import bindparam, case, func, select
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
        """Fuzzy search across name and brand.

        Strategy:
        - For very short queries (< 3 chars) we fall back to plain ILIKE prefix
          to keep results predictable and avoid noisy trigram matches.
        - For longer queries we use pg_trgm: combine an ILIKE '%q%' filter
          (uses GIN index) with similarity-based ordering plus deterministic
          tiebreakers (exact match -> prefix -> contains -> alpha).
        """
        normalized_query = query.strip()
        if not normalized_query:
            return []

        lowered_query = normalized_query.lower()
        ilike_pattern = f'%{normalized_query}%'

        # Boost tier: exact (0) -> prefix (1) -> substring (2) -> other (3)
        ranking = case(
            (func.lower(Food.name) == lowered_query, 0),
            (func.lower(Food.name).like(f'{lowered_query}%'), 1),
            (func.lower(Food.name).like(f'%{lowered_query}%'), 2),
            else_=3,
        )

        # Trigram similarity (only meaningful for 3+ char queries).
        # similarity() returns a float in [0,1]; higher is more similar.
        if len(normalized_query) >= 3:
            similarity = func.greatest(
                func.similarity(Food.name, normalized_query),
                func.coalesce(func.similarity(Food.brand, normalized_query), 0.0),
            )
            stmt = (
                select(Food)
                .options(selectinload(Food.nutrients))
                .where(
                    Food.name.ilike(ilike_pattern)
                    | Food.brand.ilike(ilike_pattern)
                )
                .order_by(ranking, similarity.desc(), Food.name.asc())
                .limit(limit)
            )
        else:
            stmt = (
                select(Food)
                .options(selectinload(Food.nutrients))
                .where(Food.name.ilike(ilike_pattern))
                .order_by(ranking, Food.name.asc())
                .limit(limit)
            )

        result = await self.session.scalars(stmt)
        return list(result)

    async def has_foods(self) -> bool:
        count = await self.session.scalar(select(func.count(Food.id)))
        return bool(count)

    async def get_food_by_barcode(self, barcode: str) -> Food | None:
        normalized = barcode.strip()
        if not normalized:
            return None
        result = await self.session.execute(
            select(Food)
            .options(selectinload(Food.nutrients))
            .where(Food.barcode == normalized)
        )
        return result.scalar_one_or_none()

    def create_food(
        self,
        *,
        name: str,
        brand: str | None,
        default_serving_amount,
        default_serving_unit: str | None,
        source: str,
        is_verified: bool,
        barcode: str | None = None,
    ) -> Food:
        food = Food(
            name=name,
            brand=brand,
            barcode=barcode,
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
