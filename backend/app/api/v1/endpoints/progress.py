from fastapi import APIRouter, Depends, status

from app.api.dependencies import get_current_user, get_progress_service
from app.application.services.progress_service import ProgressService
from app.domain.progress.schemas import (
    MeasurementLogCreateRequest,
    MeasurementLogListRead,
    MeasurementLogRead,
    ProgressOverviewRead,
    WeightLogCreateRequest,
    WeightLogListRead,
    WeightLogRead,
)
from app.domain.users.models import User

router = APIRouter()


@router.get('/overview', response_model=ProgressOverviewRead, summary='Get progress overview')
async def read_progress_overview(
    current_user: User = Depends(get_current_user),
    progress_service: ProgressService = Depends(get_progress_service),
) -> ProgressOverviewRead:
    return await progress_service.get_overview(current_user.id)


@router.get('/weight', response_model=WeightLogListRead, summary='List weight logs')
async def read_weight_logs(
    current_user: User = Depends(get_current_user),
    progress_service: ProgressService = Depends(get_progress_service),
) -> WeightLogListRead:
    return await progress_service.list_weight_logs(current_user.id)


@router.post(
    '/weight',
    response_model=WeightLogRead,
    status_code=status.HTTP_201_CREATED,
    summary='Create a weight log',
)
async def create_weight_log(
    payload: WeightLogCreateRequest,
    current_user: User = Depends(get_current_user),
    progress_service: ProgressService = Depends(get_progress_service),
) -> WeightLogRead:
    return await progress_service.create_weight_log(current_user.id, payload)


@router.get(
    '/measurements',
    response_model=MeasurementLogListRead,
    summary='List measurement logs',
)
async def read_measurement_logs(
    current_user: User = Depends(get_current_user),
    progress_service: ProgressService = Depends(get_progress_service),
) -> MeasurementLogListRead:
    return await progress_service.list_measurement_logs(current_user.id)


@router.post(
    '/measurements',
    response_model=MeasurementLogRead,
    status_code=status.HTTP_201_CREATED,
    summary='Create a measurement log',
)
async def create_measurement_log(
    payload: MeasurementLogCreateRequest,
    current_user: User = Depends(get_current_user),
    progress_service: ProgressService = Depends(get_progress_service),
) -> MeasurementLogRead:
    return await progress_service.create_measurement_log(current_user.id, payload)
