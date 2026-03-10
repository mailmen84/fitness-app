from app.domain.health.schemas import HealthResponse


class HealthService:
    def get_health(self) -> HealthResponse:
        return HealthResponse(status='ok', service='fitness-app-backend')

