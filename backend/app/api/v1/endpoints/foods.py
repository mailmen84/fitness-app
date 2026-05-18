from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.dependencies import get_current_user, get_foods_service
from app.application.services.foods_service import FoodsService
from app.domain.foods.schemas import (
    FoodCreateRequest,
    FoodDetailRead,
    FoodSearchResultsRead,
    OpenFoodFactsLookup,
)
from app.domain.users.models import User

router = APIRouter()


@router.get('/search', response_model=FoodSearchResultsRead, summary='Search foods')
async def search_foods(
    q: str = Query(default='', alias='q'),
    foods_service: FoodsService = Depends(get_foods_service),
) -> FoodSearchResultsRead:
    return await foods_service.search_foods(query=q, limit=20)


@router.get(
    '/by-barcode/{barcode}',
    response_model=FoodDetailRead,
    summary='Find a food in the local DB by its barcode',
)
async def read_food_by_barcode(
    barcode: str,
    _: User = Depends(get_current_user),
    foods_service: FoodsService = Depends(get_foods_service),
) -> FoodDetailRead:
    food = await foods_service.get_food_by_barcode(barcode)
    if food is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='No local food matches this barcode.',
        )
    return food


@router.get(
    '/openfoodfacts/{barcode}',
    response_model=OpenFoodFactsLookup,
    summary='Look up a barcode on OpenFoodFacts (returns a draft, does not save)',
)
async def lookup_openfoodfacts(
    barcode: str,
    _: User = Depends(get_current_user),
    foods_service: FoodsService = Depends(get_foods_service),
) -> OpenFoodFactsLookup:
    return await foods_service.lookup_openfoodfacts(barcode)


@router.post(
    '',
    response_model=FoodDetailRead,
    status_code=status.HTTP_201_CREATED,
    summary='Create a new food (custom or imported from OFF)',
)
async def create_food(
    payload: FoodCreateRequest,
    _: User = Depends(get_current_user),
    foods_service: FoodsService = Depends(get_foods_service),
) -> FoodDetailRead:
    try:
        return await foods_service.create_food_from_request(payload)
    except ValueError as error:
        if str(error) == 'barcode_taken':
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail='A food with this barcode already exists.',
            ) from error
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Food payload is invalid.',
        ) from error


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
