from fastapi import APIRouter, Depends, HTTPException, status

from app.api.dependencies import get_auth_service, get_current_user
from app.application.services.auth_service import AuthService
from app.domain.auth.schemas import AuthLoginRequest, AuthSessionRead, AuthSignupRequest, AuthTokenRead
from app.domain.users.models import User

router = APIRouter()


def _email_in_use_http_exception() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail='That email address is already in use.',
    )


def _invalid_credentials_http_exception() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail='Email or password is incorrect.',
        headers={'WWW-Authenticate': 'Bearer'},
    )


@router.post('/signup', response_model=AuthTokenRead, status_code=status.HTTP_201_CREATED)
async def signup(
    payload: AuthSignupRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthTokenRead:
    try:
        return await auth_service.signup(payload)
    except ValueError as error:
        if str(error) != 'email_already_in_use':
            raise
        raise _email_in_use_http_exception() from error


@router.post('/login', response_model=AuthTokenRead)
async def login(
    payload: AuthLoginRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthTokenRead:
    try:
        return await auth_service.login(payload)
    except PermissionError as error:
        if str(error) != 'invalid_credentials':
            raise
        raise _invalid_credentials_http_exception() from error


@router.get('/session', response_model=AuthSessionRead)
async def read_current_session(
    current_user: User = Depends(get_current_user),
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthSessionRead:
    return await auth_service.get_current_session(current_user)
