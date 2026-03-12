from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.dependencies import get_current_user, get_meals_service
from app.application.services.meals_service import MealsService
from app.domain.meals.schemas import (
    DeleteResponse,
    MealEntryCreateRequest,
    MealEntryUpdateRequest,
    TodayMealEntryRead,
    TodayMealsRead,
)
from app.domain.users.models import User

router = APIRouter()


def _meal_entry_lookup_http_exception(error: LookupError) -> HTTPException:
    detail = 'Food was not found.' if str(error) == 'food_not_found' else 'Meal entry was not found.'
    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=detail,
    )


def _meal_entry_payload_http_exception(error: ValueError) -> HTTPException:
    detail_by_code = {
        'unit_mismatch': 'The requested unit does not match the selected food serving unit.',
        'food_required': 'A meal entry must stay linked to a food item in the current MVP.',
    }
    return HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=detail_by_code.get(str(error), 'Meal entry payload is invalid.'),
    )


@router.get('', response_model=TodayMealsRead, summary='Get meals for a selected day')
async def read_meals_for_day(
    date: date,
    current_user: User = Depends(get_current_user),
    meals_service: MealsService = Depends(get_meals_service),
) -> TodayMealsRead:
    return await meals_service.get_day_meals(current_user.id, date)


@router.post(
    '/entries',
    response_model=TodayMealEntryRead,
    status_code=status.HTTP_201_CREATED,
    summary='Create a meal entry',
)
async def create_meal_entry(
    payload: MealEntryCreateRequest,
    current_user: User = Depends(get_current_user),
    meals_service: MealsService = Depends(get_meals_service),
) -> TodayMealEntryRead:
    try:
        return await meals_service.create_meal_entry(current_user.id, payload)
    except LookupError as error:
        raise _meal_entry_lookup_http_exception(error) from error
    except ValueError as error:
        raise _meal_entry_payload_http_exception(error) from error


@router.patch('/entries/{entry_id}', response_model=TodayMealEntryRead, summary='Update a meal entry')
async def update_meal_entry(
    entry_id: UUID,
    payload: MealEntryUpdateRequest,
    current_user: User = Depends(get_current_user),
    meals_service: MealsService = Depends(get_meals_service),
) -> TodayMealEntryRead:
    try:
        return await meals_service.update_meal_entry(current_user.id, entry_id, payload)
    except LookupError as error:
        raise _meal_entry_lookup_http_exception(error) from error
    except ValueError as error:
        raise _meal_entry_payload_http_exception(error) from error


@router.delete('/entries/{entry_id}', response_model=DeleteResponse, summary='Delete a meal entry')
async def delete_meal_entry(
    entry_id: UUID,
    current_user: User = Depends(get_current_user),
    meals_service: MealsService = Depends(get_meals_service),
) -> DeleteResponse:
    try:
        return await meals_service.delete_meal_entry(current_user.id, entry_id)
    except LookupError as error:
        raise _meal_entry_lookup_http_exception(error) from error

