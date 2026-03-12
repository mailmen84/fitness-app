import asyncio
from types import SimpleNamespace
from uuid import uuid4

import pytest

from app.application.services.auth_service import AuthService
from app.core.config import Settings
from app.core.security import (
    WeakPasswordError,
    create_access_token,
    decode_access_token,
    generate_one_time_token,
    hash_one_time_token,
    validate_password_strength,
    verify_one_time_token,
)


class FakeUsersRepository:
    def __init__(self, user):
        self.user = user

    async def get_user_with_profile(self, user_id):  # noqa: ANN001
        if user_id == self.user.id:
            return self.user
        return None


def _settings() -> Settings:
    return Settings(
        environment='test',
        auth_secret_key='test-secret-key-for-auth-hardening-12345',
    )


def test_access_token_round_trips_with_security_claims() -> None:
    settings = _settings()
    token = create_access_token(
        subject='user-123',
        secret_key=settings.auth_secret_key,
        expires_in_seconds=60,
        additional_claims={'ver': 3},
    )

    payload = decode_access_token(token, secret_key=settings.auth_secret_key)

    assert payload['sub'] == 'user-123'
    assert payload['ver'] == 3
    assert payload['exp'] > payload['iat']
    assert payload['nbf'] == payload['iat']
    assert isinstance(payload['jti'], str)


def test_one_time_token_hash_verification_round_trips() -> None:
    token = generate_one_time_token()
    token_hash = hash_one_time_token(token)

    assert verify_one_time_token(token, token_hash) is True
    assert verify_one_time_token('different-token', token_hash) is False


@pytest.mark.parametrize(
    ('password', 'code'),
    [
        ('short7', 'password_too_short'),
        ('12345678', 'password_requires_letter'),
        ('passwordonly', 'password_requires_number'),
    ],
)
def test_password_strength_validation_rejects_weak_passwords(password: str, code: str) -> None:
    with pytest.raises(WeakPasswordError, match=code):
        validate_password_strength(password)


def test_auth_service_rejects_access_tokens_with_old_token_version() -> None:
    user = SimpleNamespace(
        id=uuid4(),
        is_active=True,
        auth_token_version=2,
    )
    service = AuthService(
        users_repository=FakeUsersRepository(user),
        preferences_repository=SimpleNamespace(),
        settings=_settings(),
    )
    token = create_access_token(
        subject=str(user.id),
        secret_key=service.settings.auth_secret_key,
        expires_in_seconds=60,
        additional_claims={'ver': 1},
    )

    with pytest.raises(PermissionError, match='invalid_access_token'):
        asyncio.run(service.get_authenticated_user(token))


def test_auth_service_accepts_older_tokens_without_version_when_user_is_still_on_v1() -> None:
    user = SimpleNamespace(
        id=uuid4(),
        is_active=True,
        auth_token_version=1,
    )
    service = AuthService(
        users_repository=FakeUsersRepository(user),
        preferences_repository=SimpleNamespace(),
        settings=_settings(),
    )
    token = create_access_token(
        subject=str(user.id),
        secret_key=service.settings.auth_secret_key,
        expires_in_seconds=60,
    )

    authenticated_user = asyncio.run(service.get_authenticated_user(token))

    assert authenticated_user.id == user.id
