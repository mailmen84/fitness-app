from datetime import date
from decimal import Decimal
from uuid import UUID

from sqlalchemy import select

from app.domain.goals.models import Goal
from app.infrastructure.persistence.repositories.base_repository import BaseRepository


class GoalsRepository(BaseRepository):
    async def get_current_for_user(self, user_id: UUID) -> Goal | None:
        result = await self.session.execute(
            select(Goal)
            .where(Goal.user_id == user_id, Goal.is_active.is_(True))
            .order_by(Goal.updated_at.desc(), Goal.created_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    async def list_for_user(self, user_id: UUID) -> list[Goal]:
        result = await self.session.scalars(
            select(Goal)
            .where(Goal.user_id == user_id)
            .order_by(Goal.created_at.desc())
        )
        return list(result)

    def create_goal(
        self,
        *,
        user_id: UUID,
        code: str,
        title: str,
        target_value: Decimal | None = None,
        target_unit: str | None = None,
        is_active: bool = True,
        starts_on: date | None = None,
        ends_on: date | None = None,
        notes: str | None = None,
    ) -> Goal:
        goal = Goal(
            user_id=user_id,
            code=code,
            title=title,
            target_value=target_value,
            target_unit=target_unit,
            is_active=is_active,
            starts_on=starts_on,
            ends_on=ends_on,
            notes=notes,
        )
        self.add(goal)
        return goal