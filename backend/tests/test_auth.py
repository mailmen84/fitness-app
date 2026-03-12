from datetime import datetime, timezone
from types import SimpleNamespace
from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import get_auth_service, get_current_user
from app.domain.auth.schemas import AuthChallengeRead, AuthMessageRead, AuthSessionRead, AuthTokenRead
from app.domain.users.schemas import UserProfileRead, UserWithProfileRead
from app.main import app

client = TestClient(app)


class FakeAuthService:
    async def signup(self, payload):  # noqa: ANN001
        return AuthTokenRead(
            access_token='signup-token',
            expires_in=43200,
            session=self._session(
                email=payload.email,
                display_name=payload.display_name,
                onboarding_completed=False,
                email_verified=False,
            ),
        )

    async def login(self, payload):  # noqa: ANN001
        if payload.password != 'password123':
            raise PermissionError('invalid_credentials')
        return AuthTokenRead(
            access_token='login-token',
            expires_in=43200,
            session=self._session(
                email=payload.email,
                display_name='Preview User',
                onboarding_completed=True,
                email_verified=False,
            ),
        )

    async def request_password_reset(self, payload):  # noqa: ANN001
        return AuthChallengeRead(
            detail='If that account exists, password reset instructions are ready.',
            expires_in=3600,
            preview_token='preview-reset-token-1234567890',
        )

    async def reset_password(self, payload):  # noqa: ANN001
        if payload.token != 'preview-reset-token-1234567890':
            raise PermissionError('invalid_password_reset_token')
        return AuthTokenRead(
            access_token='reset-token',
            expires_in=43200,
            session=self._session(
                email='preview.user@example.com',
                display_name='Preview User',
                onboarding_completed=True,
                email_verified=False,
            ),
        )

    async def request_email_verification(self, user):  # noqa: ANN001
        return AuthChallengeRead(
            detail='Email verification instructions are ready.',
            expires_in=86400,
            preview_token='preview-verification-token',
        )

    async def confirm_email_verification(self, payload):  # noqa: ANN001
        if payload.token != 'preview-verification-token':
            raise PermissionError('invalid_email_verification_token')
        return AuthMessageRead(detail='Email address verified.')

    async def get_current_session(self, user):  # noqa: ANN001
        return self._session(
            email=user.email,
            display_name='Preview User',
            onboarding_completed=True,
            email_verified=False,
        )

    @staticmethod
    def _session(
        *,
        email: str,
        display_name: str,
        onboarding_completed: bool,
        email_verified: bool,
    ) -> AuthSessionRead:
        return AuthSessionRead(
            user=UserWithProfileRead(
                id=uuid4(),
                created_at=datetime(2026, 3, 12, 9, 0, tzinfo=timezone.utc),
                updated_at=datetime(2026, 3, 12, 9, 0, tzinfo=timezone.utc),
                email=email,
                is_active=True,
                email_verified=email_verified,
                profile=UserProfileRead(
                    id=uuid4(),
                    created_at=datetime(2026, 3, 12, 9, 0, tzinfo=timezone.utc),
                    updated_at=datetime(2026, 3, 12, 9, 0, tzinfo=timezone.utc),
                    user_id=uuid4(),
                    display_name=display_name,
                    first_name='Preview',
                    last_name='User',
                    birth_date=None,
                    height_cm=None,
                    bio=None,
                ),
            ),
            onboarding_completed=onboarding_completed,
        )


async def override_current_user():
    return SimpleNamespace(
        id=uuid4(),
        email='preview.user@example.com',
        is_active=True,
        email_verified=False,
    )


def override_auth_service() -> FakeAuthService:
    return FakeAuthService()


def test_signup_endpoint_returns_token_and_session_shape() -> None:
    app.dependency_overrides[get_auth_service] = override_auth_service

    response = client.post(
        '/api/v1/auth/signup',
        json={
            'display_name': 'Preview User',
            'email': 'preview.user@example.com',
            'password': 'password123',
        },
    )

    app.dependency_overrides.clear()

    assert response.status_code == 201
    payload = response.json()
    assert payload['access_token'] == 'signup-token'
    assert payload['session']['user']['email'] == 'preview.user@example.com'
    assert payload['session']['user']['email_verified'] is False
    assert payload['session']['onboarding_completed'] is False


def test_login_endpoint_returns_invalid_credentials_when_password_is_wrong() -> None:
    app.dependency_overrides[get_auth_service] = override_auth_service

    response = client.post(
        '/api/v1/auth/login',
        json={
            'email': 'preview.user@example.com',
            'password': 'wrong-password',
        },
    )

    app.dependency_overrides.clear()

    assert response.status_code == 401
    assert response.json()['detail'] == 'Email or password is incorrect.'


def test_password_reset_request_returns_generic_detail_and_preview_token() -> None:
    app.dependency_overrides[get_auth_service] = override_auth_service

    response = client.post(
        '/api/v1/auth/password-reset/request',
        json={'email': 'preview.user@example.com'},
    )

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['detail'] == 'If that account exists, password reset instructions are ready.'
    assert payload['preview_token'] == 'preview-reset-token-1234567890'


def test_password_reset_confirm_returns_token_and_session_shape() -> None:
    app.dependency_overrides[get_auth_service] = override_auth_service

    response = client.post(
        '/api/v1/auth/password-reset/confirm',
        json={
            'token': 'preview-reset-token-1234567890',
            'new_password': 'newpassword123',
        },
    )

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['access_token'] == 'reset-token'
    assert payload['session']['user']['email'] == 'preview.user@example.com'


def test_email_verification_request_returns_preview_token_when_authenticated() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_auth_service] = override_auth_service

    response = client.post(
        '/api/v1/auth/email-verification/request',
        headers={'Authorization': 'Bearer session-token'},
    )

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['preview_token'] == 'preview-verification-token'


def test_email_verification_confirm_returns_success_detail() -> None:
    app.dependency_overrides[get_auth_service] = override_auth_service

    response = client.post(
        '/api/v1/auth/email-verification/confirm',
        json={'token': 'preview-verification-token'},
    )

    app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json()['detail'] == 'Email address verified.'


def test_auth_session_endpoint_returns_authenticated_session_shape() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_auth_service] = override_auth_service

    response = client.get(
        '/api/v1/auth/session',
        headers={'Authorization': 'Bearer session-token'},
    )

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['user']['email'] == 'preview.user@example.com'
    assert payload['user']['email_verified'] is False
    assert payload['onboarding_completed'] is True


def test_protected_routes_require_bearer_auth() -> None:
    response = client.get('/api/v1/users/me')

    assert response.status_code == 401
    assert response.json()['detail'] == 'Authentication is required.'

