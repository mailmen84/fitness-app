from datetime import datetime, timezone
from decimal import Decimal
from types import SimpleNamespace
from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import get_current_user, get_progress_service
from app.domain.progress.schemas import (
    LatestMeasurementSummaryRead,
    MeasurementLogListRead,
    MeasurementLogRead,
    ProgressGoalSummaryRead,
    ProgressOverviewRead,
    WeightLogListRead,
    WeightLogRead,
)
from app.main import app

client = TestClient(app)


class FakeProgressService:
    async def get_overview(self, user_id):  # noqa: ANN001
        latest_weight = WeightLogRead(
            id=uuid4(),
            created_at=datetime(2026, 3, 11, 8, 0, tzinfo=timezone.utc),
            updated_at=datetime(2026, 3, 11, 8, 0, tzinfo=timezone.utc),
            user_id=user_id,
            measured_at=datetime(2026, 3, 11, 7, 30, tzinfo=timezone.utc),
            weight=Decimal('84.20'),
            unit='kg',
            note='Morning check-in',
        )
        previous_weight = WeightLogRead(
            id=uuid4(),
            created_at=datetime(2026, 3, 4, 8, 0, tzinfo=timezone.utc),
            updated_at=datetime(2026, 3, 4, 8, 0, tzinfo=timezone.utc),
            user_id=user_id,
            measured_at=datetime(2026, 3, 4, 7, 30, tzinfo=timezone.utc),
            weight=Decimal('85.00'),
            unit='kg',
            note=None,
        )
        return ProgressOverviewRead(
            latest_weight=latest_weight,
            previous_weight=previous_weight,
            weight_change=Decimal('-0.80'),
            weight_change_unit='kg',
            latest_measurements=[
                LatestMeasurementSummaryRead(
                    measurement_type='waist',
                    measured_at=datetime(2026, 3, 10, 18, 0, tzinfo=timezone.utc),
                    value=Decimal('82.00'),
                    unit='cm',
                )
            ],
            current_goal=ProgressGoalSummaryRead(
                id=uuid4(),
                code='cut',
                title='Cut to 82 kg',
                target_value=Decimal('82.00'),
                target_unit='kg',
            ),
        )

    async def list_weight_logs(self, user_id):  # noqa: ANN001
        return WeightLogListRead(
            items=[
                WeightLogRead(
                    id=uuid4(),
                    created_at=datetime(2026, 3, 11, 8, 0, tzinfo=timezone.utc),
                    updated_at=datetime(2026, 3, 11, 8, 0, tzinfo=timezone.utc),
                    user_id=user_id,
                    measured_at=datetime(2026, 3, 11, 7, 30, tzinfo=timezone.utc),
                    weight=Decimal('84.20'),
                    unit='kg',
                    note='Morning check-in',
                )
            ]
        )

    async def create_weight_log(self, user_id, payload):  # noqa: ANN001
        return WeightLogRead(
            id=uuid4(),
            created_at=datetime(2026, 3, 11, 8, 5, tzinfo=timezone.utc),
            updated_at=datetime(2026, 3, 11, 8, 5, tzinfo=timezone.utc),
            user_id=user_id,
            measured_at=payload.measured_at,
            weight=payload.weight,
            unit=payload.unit,
            note=payload.note,
        )

    async def list_measurement_logs(self, user_id):  # noqa: ANN001
        return MeasurementLogListRead(
            items=[
                MeasurementLogRead(
                    id=uuid4(),
                    created_at=datetime(2026, 3, 10, 18, 5, tzinfo=timezone.utc),
                    updated_at=datetime(2026, 3, 10, 18, 5, tzinfo=timezone.utc),
                    user_id=user_id,
                    measurement_type='waist',
                    measured_at=datetime(2026, 3, 10, 18, 0, tzinfo=timezone.utc),
                    value=Decimal('82.00'),
                    unit='cm',
                    note=None,
                )
            ]
        )

    async def create_measurement_log(self, user_id, payload):  # noqa: ANN001
        return MeasurementLogRead(
            id=uuid4(),
            created_at=datetime(2026, 3, 11, 8, 10, tzinfo=timezone.utc),
            updated_at=datetime(2026, 3, 11, 8, 10, tzinfo=timezone.utc),
            user_id=user_id,
            measurement_type=payload.measurement_type,
            measured_at=payload.measured_at,
            value=payload.value,
            unit=payload.unit,
            note=payload.note,
        )


async def override_current_user():
    return SimpleNamespace(id=uuid4())


def override_progress_service() -> FakeProgressService:
    return FakeProgressService()


def test_progress_overview_endpoint_returns_stable_shape() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_progress_service] = override_progress_service

    response = client.get('/api/v1/progress/overview')

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload['latest_weight']['unit'] == 'kg'
    assert payload['weight_change'] in ('-0.80', -0.8)
    assert payload['latest_measurements'][0]['measurement_type'] == 'waist'
    assert payload['current_goal']['title'] == 'Cut to 82 kg'


def test_progress_weight_routes_return_list_and_create_shapes() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_progress_service] = override_progress_service

    list_response = client.get('/api/v1/progress/weight')
    create_response = client.post(
        '/api/v1/progress/weight',
        json={
            'measured_at': '2026-03-11T07:30:00Z',
            'weight': 84.2,
            'unit': 'kg',
            'note': 'Morning check-in',
        },
    )

    app.dependency_overrides.clear()

    assert list_response.status_code == 200
    assert list_response.json()['items'][0]['weight'] in ('84.20', 84.2)
    assert create_response.status_code == 201
    assert create_response.json()['note'] == 'Morning check-in'


def test_progress_measurement_routes_return_list_and_create_shapes() -> None:
    app.dependency_overrides[get_current_user] = override_current_user
    app.dependency_overrides[get_progress_service] = override_progress_service

    list_response = client.get('/api/v1/progress/measurements')
    create_response = client.post(
        '/api/v1/progress/measurements',
        json={
            'measurement_type': 'waist',
            'measured_at': '2026-03-11T08:00:00Z',
            'value': 82,
            'unit': 'cm',
        },
    )

    app.dependency_overrides.clear()

    assert list_response.status_code == 200
    assert list_response.json()['items'][0]['measurement_type'] == 'waist'
    assert create_response.status_code == 201
    assert create_response.json()['unit'] == 'cm'
