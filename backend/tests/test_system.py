from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_system_endpoint_returns_backend_summary() -> None:
    response = client.get('/api/v1/system/foundation')

    assert response.status_code == 200
    payload = response.json()
    assert payload['service'] == 'Fitness App API'
    assert payload['database']['migrations'] == 'alembic configured'
    assert any(resource['name'] == 'auth' for resource in payload['resources'])
    assert any(resource['status'] == 'working_mvp' for resource in payload['resources'])
