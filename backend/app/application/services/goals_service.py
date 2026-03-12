from uuid import UUID

from app.domain.goals.models import Goal
from app.domain.goals.schemas import CurrentGoalPutRequest
from app.infrastructure.persistence.repositories.goals_repository import GoalsRepository


class GoalsService:
    def __init__(self, goals_repository: GoalsRepository):
        self.goals_repository = goals_repository

    async def list_goals_for_user(self, user_id: UUID) -> list[Goal]:
        return await self.goals_repository.list_for_user(user_id)

    async def get_current_goal(self, user_id: UUID) -> Goal | None:
        return await self.goals_repository.get_current_for_user(user_id)

    async def put_current_goal(self, user_id: UUID, payload: CurrentGoalPutRequest) -> Goal:
        goal = await self.goals_repository.get_current_for_user(user_id)
        payload_data = payload.model_dump()

        if goal is None:
            goal = self.goals_repository.create_goal(
                user_id=user_id,
                code=payload_data['code'],
                title=payload_data['title'],
                target_value=payload_data['target_value'],
                target_unit=payload_data['target_unit'],
                starts_on=payload_data['starts_on'],
                ends_on=payload_data['ends_on'],
                notes=payload_data['notes'],
            )
        else:
            goal.code = payload_data['code']
            goal.title = payload_data['title']
            goal.target_value = payload_data['target_value']
            goal.target_unit = payload_data['target_unit']
            goal.starts_on = payload_data['starts_on']
            goal.ends_on = payload_data['ends_on']
            goal.notes = payload_data['notes']
            goal.is_active = True

        await self.goals_repository.commit()
        await self.goals_repository.refresh(goal)
        return goal