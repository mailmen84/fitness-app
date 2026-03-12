from fastapi import APIRouter, Depends

from app.api.dependencies import get_system_service
from app.application.services.system_service import SystemService
from app.domain.system.schemas import SystemFoundationResponse

router = APIRouter()


@router.get('/foundation', response_model=SystemFoundationResponse, summary='Runtime overview')
async def read_foundation(
    system_service: SystemService = Depends(get_system_service),
) -> SystemFoundationResponse:
    return system_service.get_foundation_summary()
