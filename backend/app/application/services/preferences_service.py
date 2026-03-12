from uuid import UUID

from app.domain.preferences.models import Preference
from app.domain.preferences.schemas import PreferencePutRequest
from app.infrastructure.persistence.repositories.preferences_repository import (
    PreferencesRepository,
)


class PreferencesService:
    def __init__(self, preferences_repository: PreferencesRepository):
        self.preferences_repository = preferences_repository

    async def get_preferences_for_user(self, user_id: UUID) -> Preference | None:
        return await self.preferences_repository.get_for_user(user_id)

    async def get_preferences(self, user_id: UUID) -> Preference:
        preference = await self.preferences_repository.get_for_user(user_id)
        if preference is None:
            preference = self.preferences_repository.create_for_user(user_id=user_id)
            await self.preferences_repository.commit()
            await self.preferences_repository.refresh(preference)
        return preference

    async def put_preferences(self, user_id: UUID, payload: PreferencePutRequest) -> Preference:
        preference = await self.preferences_repository.get_for_user(user_id)
        if preference is None:
            preference = self.preferences_repository.create_for_user(user_id=user_id)

        for field, value in payload.model_dump(exclude_unset=True).items():
            setattr(preference, field, value)

        await self.preferences_repository.commit()
        await self.preferences_repository.refresh(preference)
        return preference