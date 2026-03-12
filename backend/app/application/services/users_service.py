from uuid import UUID

from app.domain.users.models import User, UserProfile
from app.domain.users.schemas import CurrentUserUpdate
from app.infrastructure.persistence.repositories.users_repository import UsersRepository


class UsersService:
    def __init__(self, users_repository: UsersRepository):
        self.users_repository = users_repository

    @staticmethod
    def _split_display_name(display_name: str | None) -> tuple[str | None, str | None]:
        if not display_name:
            return None, None

        parts = display_name.split()
        if not parts:
            return None, None
        if len(parts) == 1:
            return parts[0], None
        return parts[0], ' '.join(parts[1:])

    async def get_user(self, user_id: UUID) -> User | None:
        return await self.users_repository.get_user(user_id)

    async def get_profile(self, user_id: UUID) -> UserProfile | None:
        return await self.users_repository.get_profile_for_user(user_id)

    async def get_or_create_development_user(
        self,
        *,
        email: str,
        display_name: str,
    ) -> User:
        user = await self.users_repository.get_by_email(email)
        needs_commit = False

        if user is None:
            user = self.users_repository.create_user(email=email)
            await self.users_repository.flush()
            needs_commit = True

        profile = await self.users_repository.get_profile_for_user(user.id)
        if profile is None:
            first_name, last_name = self._split_display_name(display_name)
            self.users_repository.create_profile(
                user_id=user.id,
                display_name=display_name,
                first_name=first_name,
                last_name=last_name,
            )
            needs_commit = True

        if needs_commit:
            await self.users_repository.commit()

        current_user = await self.users_repository.get_user_with_profile(user.id)
        return current_user or user

    async def get_current_user(self, user_id: UUID) -> User | None:
        return await self.users_repository.get_user_with_profile(user_id)

    async def update_current_user(self, user_id: UUID, payload: CurrentUserUpdate) -> User:
        user = await self.users_repository.get_user_with_profile(user_id)
        if user is None:
            raise LookupError('current_user_not_found')

        payload_data = payload.model_dump(exclude_unset=True)
        email = payload_data.get('email')
        if email and email != user.email:
            existing_user = await self.users_repository.get_by_email(email)
            if existing_user is not None and existing_user.id != user_id:
                raise ValueError('email_already_in_use')
            user.email = email

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