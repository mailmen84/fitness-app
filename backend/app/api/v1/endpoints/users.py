from fastapi import APIRouter, Depends, HTTPException, status

from app.api.dependencies import get_current_user, get_users_service
from app.application.services.users_service import UsersService
from app.domain.users.models import User
from app.domain.users.schemas import CurrentUserUpdate, UserWithProfileRead

router = APIRouter()


@router.get('/me', response_model=UserWithProfileRead, summary='Get the current user')
async def read_current_user(
    current_user: User = Depends(get_current_user),
    users_service: UsersService = Depends(get_users_service),
) -> User:
    user = await users_service.get_current_user(current_user.id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Current user was not found.',
        )
    return user


@router.patch('/me', response_model=UserWithProfileRead, summary='Update the current user')
async def update_current_user(
    payload: CurrentUserUpdate,
    current_user: User = Depends(get_current_user),
    users_service: UsersService = Depends(get_users_service),
) -> User:
    try:
        return await users_service.update_current_user(current_user.id, payload)
    except LookupError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Current user was not found.',
        ) from error
    except ValueError as error:
        if str(error) != 'email_already_in_use':
            raise
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail='That email address is already in use.',
        ) from error