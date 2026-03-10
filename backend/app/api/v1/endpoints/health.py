from fastapi import APIRouter

from app.application.services.health_service import HealthService
from app.domain.health.schemas import HealthResponse

router = APIRouter()


@router.get('', response_model=HealthResponse, summary='Health check')
async def read_health() -> HealthResponse:
    return HealthService().get_health()

