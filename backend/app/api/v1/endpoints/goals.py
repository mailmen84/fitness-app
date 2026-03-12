from fastapi import APIRouter, Depends

from app.api.dependencies import get_current_user, get_goals_service
from app.application.services.goals_service import GoalsService
from app.domain.goals.models import Goal
from app.domain.goals.schemas import CurrentGoalPutRequest, GoalRead
from app.domain.users.models import User

router = APIRouter()


@router.get('/current', response_model=GoalRead | None, summary='Get the current goal')
async def read_current_goal(
    current_user: User = Depends(get_current_user),
    goals_service: GoalsService = Depends(get_goals_service),
) -> Goal | None:
    return await goals_service.get_current_goal(current_user.id)


@router.put('/current', response_model=GoalRead, summary='Upsert the current goal')
async def put_current_goal(
    payload: CurrentGoalPutRequest,
    current_user: User = Depends(get_current_user),
    goals_service: GoalsService = Depends(get_goals_service),
) -> Goal:
    return await goals_service.put_current_goal(current_user.id, payload)