from datetime import date
from decimal import Decimal
from uuid import UUID

from app.domain.shared.schemas import DomainSchema, TimestampedReadSchema


class UserCreate(DomainSchema):
    email: str
    password: str | None = None


class UserUpdate(DomainSchema):
    email: str | None = None
    is_active: bool | None = None


class CurrentUserUpdate(DomainSchema):
    email: str | None = None
    display_name: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    birth_date: date | None = None
    height_cm: Decimal | None = None
    bio: str | None = None


class UserRead(TimestampedReadSchema):
    email: str
    is_active: bool
    email_verified: bool


class UserProfileCreate(DomainSchema):
    user_id: UUID
    display_name: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    birth_date: date | None = None
    height_cm: Decimal | None = None
    bio: str | None = None


class UserProfileUpdate(DomainSchema):
    display_name: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    birth_date: date | None = None
    height_cm: Decimal | None = None
    bio: str | None = None


class UserProfileRead(TimestampedReadSchema):
    user_id: UUID
    display_name: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    birth_date: date | None = None
    height_cm: Decimal | None = None
    bio: str | None = None


class UserWithProfileRead(UserRead):
    profile: UserProfileRead | None = None
