from datetime import datetime, timezone
from types import SimpleNamespace
from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import get_auth_service, get_current_user
from app.domain.auth.schemas import AuthSessionRead, AuthTokenRead
from app.domain.users.schemas import UserProfileRead, UserWithProfileRead
from app.main import app

client = TestClient(app)


class FakeAuthService:
    async def signup(self, payload):  # noqa: ANN001
        return AuthTokenRead(
            access_token='signup-token',
            expires_in=604800,
            session=self._session(
                email=payload.email,
                display_name=payload.display_name,
                onboarding_completed=False,
            ),
        )

    async def login(self, payload):  # noqa: ANN001
        if payload.password != 'password123':
            raise PermissionError('invalid_credentials')
        return AuthTokenRead(
            access_token='login-token',
            expires_in=604800,
            session=self._session(
                email=payload.email,
                display_name='Preview User',
                onboarding_completed=True,
            ),
        )

    async def get_current_session(self, user):  # noqa: ANN001
        return self._session(
            email=user.email,
            display_name='Preview User',
            onboarding_completed=True,
        )

    @staticmethod
    def _session(*, email: str, display_name: str, onboarding_completed: bool) -> AuthSessionRead:
        return AuthSessionRead(
            user=UserWithProfileRead(
                id=uuid4(),
                created_at=datetime(2026, 3, 12, 9, 0, tzinfo=timezone.utc),
                updated_at=datetime(2026, 3, 12, 9, 0, tzinfo=timezone.utc),
                email=email,
                is_active=True,
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
    assert payload['onboarding_completed'] is True


def test_protected_routes_require_bearer_auth() -> None:
    response = client.get('/api/v1/users/me')

    assert response.status_code == 401
    assert response.json()['detail'] == 'Authentication is required.'
