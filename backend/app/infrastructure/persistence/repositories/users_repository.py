from datetime import date
from decimal import Decimal
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.domain.users.models import User, UserProfile
from app.infrastructure.persistence.repositories.base_repository import BaseRepository


def _normalize_email(email: str) -> str:
    return email.strip().lower()


class UsersRepository(BaseRepository):
    async def get_user(self, user_id: UUID) -> User | None:
        return await self.session.get(User, user_id)

    async def get_user_with_profile(self, user_id: UUID) -> User | None:
        result = await self.session.execute(
            select(User)
            .options(selectinload(User.profile))
            .where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        result = await self.session.execute(
            select(User)
            .options(selectinload(User.profile))
            .where(User.email == _normalize_email(email))
        )
        return result.scalar_one_or_none()

    async def get_profile_for_user(self, user_id: UUID) -> UserProfile | None:
        result = await self.session.execute(
            select(UserProfile).where(UserProfile.user_id == user_id)
        )
        return result.scalar_one_or_none()

    def create_user(
        self,
        *,
        email: str,
        password_hash: str | None = None,
        is_active: bool = True,
    ) -> User:
        user = User(
            email=_normalize_email(email),
            password_hash=password_hash,
            is_active=is_active,
        )
        self.add(user)
        return user

    def create_profile(
        self,
        *,
        user_id: UUID,
        display_name: str | None = None,
        first_name: str | None = None,
        last_name: str | None = None,
        birth_date: date | None = None,
        height_cm: Decimal | None = None,
        bio: str | None = None,
    ) -> UserProfile:
        profile = UserProfile(
            user_id=user_id,
            display_name=display_name,
            first_name=first_name,
            last_name=last_name,
            birth_date=birth_date,
            height_cm=height_cm,
            bio=bio,
        )
        self.add(profile)
        return profile
