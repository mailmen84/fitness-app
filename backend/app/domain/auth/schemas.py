from __future__ import annotations

import re

from pydantic import Field, field_validator

from app.domain.shared.schemas import DomainSchema
from app.domain.users.schemas import UserWithProfileRead

_EMAIL_PATTERN = re.compile(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')


class AuthSignupRequest(DomainSchema):
    display_name: str = Field(min_length=1, max_length=120)
    email: str = Field(min_length=3, max_length=320)
    password: str = Field(min_length=8, max_length=128)

    @field_validator('display_name')
    @classmethod
    def _validate_display_name(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError('Display name is required.')
        return normalized

    @field_validator('email')
    @classmethod
    def _validate_email(cls, value: str) -> str:
        normalized = value.strip().lower()
        if not _EMAIL_PATTERN.match(normalized):
            raise ValueError('Enter a valid email address.')
        return normalized


class AuthLoginRequest(DomainSchema):
    email: str = Field(min_length=3, max_length=320)
    password: str = Field(min_length=8, max_length=128)

    @field_validator('email')
    @classmethod
    def _validate_email(cls, value: str) -> str:
        normalized = value.strip().lower()
        if not _EMAIL_PATTERN.match(normalized):
            raise ValueError('Enter a valid email address.')
        return normalized


class AuthPasswordResetRequest(DomainSchema):
    email: str = Field(min_length=3, max_length=320)

    @field_validator('email')
    @classmethod
    def _validate_email(cls, value: str) -> str:
        normalized = value.strip().lower()
        if not _EMAIL_PATTERN.match(normalized):
            raise ValueError('Enter a valid email address.')
        return normalized


class AuthPasswordResetConfirmRequest(DomainSchema):
    token: str = Field(min_length=20, max_length=255)
    new_password: str = Field(min_length=8, max_length=128)

    @field_validator('token')
    @classmethod
    def _validate_token(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError('Reset token is required.')
        return normalized


class AuthEmailVerificationConfirmRequest(DomainSchema):
    token: str = Field(min_length=20, max_length=255)

    @field_validator('token')
    @classmethod
    def _validate_token(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError('Verification token is required.')
        return normalized


class AuthSessionRead(DomainSchema):
    user: UserWithProfileRead
    onboarding_completed: bool


class AuthTokenRead(DomainSchema):
    access_token: str
    token_type: str = 'bearer'
    expires_in: int
    session: AuthSessionRead


class AuthMessageRead(DomainSchema):
    detail: str


class AuthChallengeRead(AuthMessageRead):
    expires_in: int | None = None
    preview_token: str | None = None
