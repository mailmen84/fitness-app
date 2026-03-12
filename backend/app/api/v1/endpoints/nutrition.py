from datetime import date

from fastapi import APIRouter, Depends, Query

from app.api.dependencies import get_current_user, get_nutrition_service
from app.application.services.nutrition_service import NutritionService
from app.domain.nutrition.schemas import (
    NutritionMacroRead,
    NutritionMetricType,
    NutritionOverviewRead,
    NutritionRange,
)
from app.domain.users.models import User

router = APIRouter()


@router.get('/overview', response_model=NutritionOverviewRead, summary='Get nutrition overview')
async def read_nutrition_overview(
    range: NutritionRange = Query(default=NutritionRange.DAY),
    date: date = Query(...),
    current_user: User = Depends(get_current_user),
    nutrition_service: NutritionService = Depends(get_nutrition_service),
) -> NutritionOverviewRead:
    return await nutrition_service.get_overview(
        current_user.id,
        range_type=range,
        anchor_date=date,
    )


@router.get('/macro/{macro_type}', response_model=NutritionMacroRead, summary='Get macro detail')
async def read_macro_detail(
    macro_type: NutritionMetricType,
    range: NutritionRange = Query(default=NutritionRange.DAY),
    date: date = Query(...),
    current_user: User = Depends(get_current_user),
    nutrition_service: NutritionService = Depends(get_nutrition_service),
) -> NutritionMacroRead:
    return await nutrition_service.get_macro_detail(
        current_user.id,
        macro_type=macro_type,
        range_type=range,
        anchor_date=date,
    )
