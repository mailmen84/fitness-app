from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.dependencies import get_foods_service
from app.application.services.foods_service import FoodsService
from app.domain.foods.schemas import FoodDetailRead, FoodSearchResultsRead

router = APIRouter()


@router.get('/search', response_model=FoodSearchResultsRead, summary='Search foods')
async def search_foods(
    q: str = Query(default='', alias='q'),
    foods_service: FoodsService = Depends(get_foods_service),
) -> FoodSearchResultsRead:
    return await foods_service.search_foods(query=q, limit=20)


@router.get('/{food_id}', response_model=FoodDetailRead, summary='Get food detail')
async def read_food_detail(
    food_id: UUID,
    foods_service: FoodsService = Depends(get_foods_service),
) -> FoodDetailRead:
    food = await foods_service.get_food_detail(food_id)
    if food is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Food was not found.',
        )
    return food
