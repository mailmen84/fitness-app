from fastapi import APIRouter, Depends, HTTPException, status

from app.api.dependencies import get_auth_service, get_current_user
from app.application.services.auth_service import AuthService
from app.domain.auth.schemas import (
    AuthChallengeRead,
    AuthEmailVerificationConfirmRequest,
    AuthLoginRequest,
    AuthMessageRead,
    AuthPasswordResetConfirmRequest,
    AuthPasswordResetRequest,
    AuthSessionRead,
    AuthSignupRequest,
    AuthTokenRead,
)
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


def _weak_password_http_exception(code: str) -> HTTPException:
    detail_by_code = {
        'password_too_short': 'Password must be at least 8 characters.',
        'password_requires_letter': 'Password must include at least one letter.',
        'password_requires_number': 'Password must include at least one number.',
    }
    return HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=detail_by_code.get(code, 'Password does not meet the minimum security rules.'),
    )


def _password_reset_token_http_exception() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail='Password reset token is invalid or has expired.',
    )


def _email_verification_token_http_exception() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail='Email verification token is invalid or has expired.',
    )


@router.post('/signup', response_model=AuthTokenRead, status_code=status.HTTP_201_CREATED)
async def signup(
    payload: AuthSignupRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthTokenRead:
    try:
        return await auth_service.signup(payload)
    except ValueError as error:
        if str(error) == 'email_already_in_use':
            raise _email_in_use_http_exception() from error
        if str(error).startswith('password_'):
            raise _weak_password_http_exception(str(error)) from error
        raise


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


@router.post('/password-reset/request', response_model=AuthChallengeRead)
async def request_password_reset(
    payload: AuthPasswordResetRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthChallengeRead:
    return await auth_service.request_password_reset(payload)


@router.post('/password-reset/confirm', response_model=AuthTokenRead)
async def confirm_password_reset(
    payload: AuthPasswordResetConfirmRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthTokenRead:
    try:
        return await auth_service.reset_password(payload)
    except ValueError as error:
        if str(error).startswith('password_'):
            raise _weak_password_http_exception(str(error)) from error
        raise
    except PermissionError as error:
        if str(error) not in {'invalid_password_reset_token', 'password_reset_token_expired'}:
            raise
        raise _password_reset_token_http_exception() from error


@router.post('/email-verification/request', response_model=AuthChallengeRead)
async def request_email_verification(
    current_user: User = Depends(get_current_user),
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthChallengeRead:
    return await auth_service.request_email_verification(current_user)


@router.post('/email-verification/confirm', response_model=AuthMessageRead)
async def confirm_email_verification(
    payload: AuthEmailVerificationConfirmRequest,
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthMessageRead:
    try:
        return await auth_service.confirm_email_verification(payload)
    except PermissionError as error:
        if str(error) not in {
            'invalid_email_verification_token',
            'email_verification_token_expired',
        }:
            raise
        raise _email_verification_token_http_exception() from error


@router.get('/session', response_model=AuthSessionRead)
async def read_current_session(
    current_user: User = Depends(get_current_user),
    auth_service: AuthService = Depends(get_auth_service),
) -> AuthSessionRead:
    return await auth_service.get_current_session(current_user)
