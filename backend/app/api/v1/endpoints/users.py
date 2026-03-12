from fastapi import APIRouter, Depends, HTTPException, status

from app.api.dependencies import get_current_user, get_users_service
from app.application.services.users_service import UsersService
from app.domain.users.models import User
from app.domain.users.schemas import CurrentUserUpdate, UserWithProfileRead

router = APIRouter()


def _current_user_not_found_http_exception() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail='Current user was not found.',
    )


def _email_already_in_use_http_exception() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail='That email address is already in use.',
    )


@router.get('/me', response_model=UserWithProfileRead, summary='Get the current user')
async def read_current_user(
    current_user: User = Depends(get_current_user),
    users_service: UsersService = Depends(get_users_service),
) -> User:
    user = await users_service.get_current_user(current_user.id)
    if user is None:
        raise _current_user_not_found_http_exception()
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
        raise _current_user_not_found_http_exception() from error
    except ValueError as error:
        if str(error) != 'email_already_in_use':
            raise
        raise _email_already_in_use_http_exception() from error
