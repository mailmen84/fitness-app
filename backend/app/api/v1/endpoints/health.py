from fastapi import APIRouter, Depends

from app.api.dependencies import get_health_service
from app.application.services.health_service import HealthService
from app.domain.health.schemas import HealthResponse

router = APIRouter()


@router.get("", response_model=HealthResponse, summary="Health check")
async def read_health(
    health_service: HealthService = Depends(get_health_service),
) -> HealthResponse:
    return health_service.get_health()