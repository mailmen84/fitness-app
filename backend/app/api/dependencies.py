from collections.abc import AsyncIterator

from fastapi import Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.services.foods_service import FoodsService
from app.application.services.goals_service import GoalsService
from app.application.services.health_service import HealthService
from app.application.services.meals_service import MealsService
from app.application.services.nutrition_service import NutritionService
from app.application.services.preferences_service import PreferencesService
from app.application.services.progress_service import ProgressService
from app.application.services.system_service import SystemService
from app.application.services.users_service import UsersService
from app.core.config import Settings, get_settings
from app.domain.users.models import User
from app.infrastructure.persistence.database import get_db_session
from app.infrastructure.persistence.repositories.foods_repository import FoodsRepository
from app.infrastructure.persistence.repositories.goals_repository import GoalsRepository
from app.infrastructure.persistence.repositories.meals_repository import MealsRepository
from app.infrastructure.persistence.repositories.preferences_repository import (
    PreferencesRepository,
)
from app.infrastructure.persistence.repositories.progress_repository import ProgressRepository
from app.infrastructure.persistence.repositories.users_repository import UsersRepository


async def get_session() -> AsyncIterator[AsyncSession]:
    async for session in get_db_session():
        yield session


def get_health_service() -> HealthService:
    return HealthService()


def get_system_service(settings: Settings = Depends(get_settings)) -> SystemService:
    return SystemService(settings=settings)


def get_users_repository(session: AsyncSession = Depends(get_session)) -> UsersRepository:
    return UsersRepository(session=session)


def get_users_service(
    users_repository: UsersRepository = Depends(get_users_repository),
) -> UsersService:
    return UsersService(users_repository=users_repository)


async def get_current_user(
    users_service: UsersService = Depends(get_users_service),
    settings: Settings = Depends(get_settings),
    x_debug_user_email: str | None = Header(default=None, alias='X-Debug-User-Email'),
    x_debug_user_name: str | None = Header(default=None, alias='X-Debug-User-Name'),
) -> User:
    # Dev-only placeholder until real token-based auth is added.
    email = x_debug_user_email or settings.dev_current_user_email
    display_name = x_debug_user_name or settings.dev_current_user_display_name
    return await users_service.get_or_create_development_user(
        email=email,
        display_name=display_name,
    )


def get_goals_repository(session: AsyncSession = Depends(get_session)) -> GoalsRepository:
    return GoalsRepository(session=session)


def get_goals_service(
    goals_repository: GoalsRepository = Depends(get_goals_repository),
) -> GoalsService:
    return GoalsService(goals_repository=goals_repository)


def get_preferences_repository(
    session: AsyncSession = Depends(get_session),
) -> PreferencesRepository:
    return PreferencesRepository(session=session)


def get_preferences_service(
    preferences_repository: PreferencesRepository = Depends(get_preferences_repository),
) -> PreferencesService:
    return PreferencesService(preferences_repository=preferences_repository)


def get_foods_repository(session: AsyncSession = Depends(get_session)) -> FoodsRepository:
    return FoodsRepository(session=session)


def get_foods_service(
    foods_repository: FoodsRepository = Depends(get_foods_repository),
) -> FoodsService:
    return FoodsService(foods_repository=foods_repository)


def get_meals_repository(session: AsyncSession = Depends(get_session)) -> MealsRepository:
    return MealsRepository(session=session)


def get_meals_service(
    meals_repository: MealsRepository = Depends(get_meals_repository),
    foods_repository: FoodsRepository = Depends(get_foods_repository),
) -> MealsService:
    return MealsService(
        meals_repository=meals_repository,
        foods_repository=foods_repository,
    )


def get_nutrition_service(
    meals_repository: MealsRepository = Depends(get_meals_repository),
    preferences_repository: PreferencesRepository = Depends(get_preferences_repository),
    goals_repository: GoalsRepository = Depends(get_goals_repository),
) -> NutritionService:
    return NutritionService(
        meals_repository=meals_repository,
        preferences_repository=preferences_repository,
        goals_repository=goals_repository,
    )


def get_progress_repository(session: AsyncSession = Depends(get_session)) -> ProgressRepository:
    return ProgressRepository(session=session)


def get_progress_service(
    progress_repository: ProgressRepository = Depends(get_progress_repository),
    goals_repository: GoalsRepository = Depends(get_goals_repository),
) -> ProgressService:
    return ProgressService(
        progress_repository=progress_repository,
        goals_repository=goals_repository,
    )
