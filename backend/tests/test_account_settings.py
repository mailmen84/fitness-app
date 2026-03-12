from datetime import date, datetime, timezone
from decimal import Decimal
from types import SimpleNamespace
from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import (
    get_current_user,
    get_goals_service,
    get_preferences_service,
    get_users_service,
)
from app.domain.goals.schemas import GoalRead
from app.domain.preferences.schemas import PreferenceRead
from app.domain.users.schemas import UserProfileRead, UserWithProfileRead
from app.main import app

client = TestClient(app)


class FakeUsersService:
    async def get_current_user(self, user_id):  # noqa: ANN001
        return UserWithProfileRead(
            id=user_id,
            created_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
            updated_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
            email='preview.user@example.com',
            is_active=True,
            profile=UserProfileRead(
                id=uuid4(),
                created_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
                updated_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
                user_id=user_id,
                display_name='Preview User',
                first_name='Preview',
                last_name='User',
                birth_date=date(1991, 5, 4),
                height_cm=Decimal('180.50'),
                bio='Initial profile summary',
            ),
        )

    async def update_current_user(self, user_id, payload):  # noqa: ANN001
        return UserWithProfileRead(
            id=user_id,
            created_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
            updated_at=datetime(2026, 3, 11, 9, 15, tzinfo=timezone.utc),
            email=payload.email or 'preview.user@example.com',
            is_active=True,
            profile=UserProfileRead(
                id=uuid4(),
                created_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
                updated_at=datetime(2026, 3, 11, 9, 15, tzinfo=timezone.utc),
                user_id=user_id,
                display_name=payload.display_name,
                first_name=payload.first_name,
                last_name=payload.last_name,
                birth_date=payload.birth_date,
                height_cm=payload.height_cm,
                bio=payload.bio,
            ),
        )


class FakeGoalsService:
    async def get_current_goal(self, user_id):  # noqa: ANN001
        return GoalRead(
            id=uuid4(),
            created_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
            updated_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
            user_id=user_id,
            code='cut',
            title='Cut to 82 kg',
            target_value=Decimal('82.00'),
            target_unit='kg',
            is_active=True,
            starts_on=date(2026, 3, 1),
            ends_on=None,
            notes='Hold a steady deficit.',
        )

    async def put_current_goal(self, user_id, payload):  # noqa: ANN001
        return GoalRead(
            id=uuid4(),
            created_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
            updated_at=datetime(2026, 3, 11, 9, 20, tzinfo=timezone.utc),
            user_id=user_id,
            code=payload.code,
            title=payload.title,
            target_value=payload.target_value,
            target_unit=payload.target_unit,
            is_active=True,
            starts_on=payload.starts_on,
            ends_on=payload.ends_on,
            notes=payload.notes,
        )


class FakePreferencesService:
    async def get_preferences(self, user_id):  # noqa: ANN001
        return PreferenceRead(
            id=uuid4(),
            created_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
            updated_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
            user_id=user_id,
            unit_system='metric',
            timezone='Europe/Dublin',
            week_starts_on='monday',
            daily_calorie_target=Decimal('2200.00'),
            daily_protein_target=Decimal('165.00'),
            onboarding_completed=True,
        )

    async def put_preferences(self, user_id, payload):  # noqa: ANN001
        return PreferenceRead(
            id=uuid4(),
            created_at=datetime(2026, 3, 11, 9, 0, tzinfo=timezone.utc),
            updated_at=datetime(2026, 3, 11, 9, 25, tzinfo=timezone.utc),
            user_id=user_id,
            unit_system=payload.unit_system,
            timezone=payload.timezone,
            week_starts_on=payload.week_starts_on,
            daily_calorie_target=payload.daily_calorie_target,
            daily_protein_target=payload.daily_protein_target,
            onboarding_completed=payload.onboarding_completed,
        )


async def override_current_user():
    return SimpleNamespace(id=uuid4())


def override_users_service() -> FakeUsersService:
    return FakeUsersService()


def override_goals_service() -> FakeGoalsService:
    return FakeGoalsService()


def override_preferences_service() -> FakePreferencesService:
    return FakePreferencesService()


def test_users_me_routes_return_profile_shapes() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_users_service] = override_users_service

    read_response = client.get('/api/v1/users/me')
    update_response = client.patch(
        '/api/v1/users/me',
        json={
            'email': 'updated.user@example.com',
            'display_name': 'Updated User',
            'first_name': 'Updated',
            'last_name': 'User',
            'birth_date': '1992-04-01',
            'height_cm': 181.5,
            'bio': 'Updated bio',
        },
    )

    app.dependency_overrides.clear()

    assert read_response.status_code == 200
    assert read_response.json()['profile']['display_name'] == 'Preview User'
    assert update_response.status_code == 200
    assert update_response.json()['email'] == 'updated.user@example.com'
    assert update_response.json()['profile']['bio'] == 'Updated bio'


def test_goals_current_routes_return_get_and_put_shapes() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_goals_service] = override_goals_service

    read_response = client.get('/api/v1/goals/current')
    put_response = client.put(
        '/api/v1/goals/current',
        json={
            'code': 'performance',
            'title': 'Build running volume',
            'target_value': 4,
            'target_unit': 'sessions',
            'starts_on': '2026-03-15',
            'ends_on': '2026-04-15',
            'notes': 'Keep the next block consistent.',
        },
    )

    app.dependency_overrides.clear()

    assert read_response.status_code == 200
    assert read_response.json()['title'] == 'Cut to 82 kg'
    assert put_response.status_code == 200
    assert put_response.json()['code'] == 'performance'
    assert put_response.json()['target_unit'] == 'sessions'


def test_preferences_routes_return_get_and_put_shapes() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_preferences_service] = override_preferences_service

    read_response = client.get('/api/v1/preferences')
    put_response = client.put(
        '/api/v1/preferences',
        json={
            'unit_system': 'imperial',
            'timezone': 'America/Chicago',
            'week_starts_on': 'sunday',
            'daily_calorie_target': 2400,
            'daily_protein_target': 175,
            'onboarding_completed': True,
        },
    )

    app.dependency_overrides.clear()

    assert read_response.status_code == 200
    assert read_response.json()['timezone'] == 'Europe/Dublin'
    assert put_response.status_code == 200
    assert put_response.json()['unit_system'] == 'imperial'
    assert put_response.json()['daily_protein_target'] in ('175', '175.00', 175)
