from uuid import UUID

from app.domain.users.models import User, UserProfile
from app.domain.users.schemas import CurrentUserUpdate
from app.infrastructure.persistence.repositories.users_repository import UsersRepository


class UsersService:
    def __init__(self, users_repository: UsersRepository):
        self.users_repository = users_repository

    @staticmethod
    def _normalize_email(email: str) -> str:
        return email.strip().lower()

    async def get_user(self, user_id: UUID) -> User | None:
        return await self.users_repository.get_user(user_id)

    async def get_profile(self, user_id: UUID) -> UserProfile | None:
        return await self.users_repository.get_profile_for_user(user_id)

    async def get_current_user(self, user_id: UUID) -> User | None:
        return await self.users_repository.get_user_with_profile(user_id)

    async def update_current_user(self, user_id: UUID, payload: CurrentUserUpdate) -> User:
        user = await self.users_repository.get_user_with_profile(user_id)
        if user is None:
            raise LookupError('current_user_not_found')

        payload_data = payload.model_dump(exclude_unset=True)
        email = payload_data.get('email')
        if email and self._normalize_email(email) != user.email:
            normalized_email = self._normalize_email(email)
            existing_user = await self.users_repository.get_by_email(normalized_email)
            if existing_user is not None and existing_user.id != user_id:
                raise ValueError('email_already_in_use')
            user.email = normalized_email

        profile_fields = {
            'display_name',
            'first_name',
            'last_name',
            'birth_date',
            'height_cm',
            'bio',
        }
        if any(field in payload_data for field in profile_fields):
            profile = user.profile
            if profile is None:
                profile = self.users_repository.create_profile(user_id=user.id)
            for field in profile_fields:
                if field in payload_data:
                    setattr(profile, field, payload_data[field])

        await self.users_repository.commit()
        current_user = await self.users_repository.get_user_with_profile(user.id)
        if current_user is None:
            raise LookupError('current_user_not_found')
        return current_user
