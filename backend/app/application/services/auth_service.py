from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID

from app.core.config import Settings
from app.core.security import (
    WeakPasswordError,
    create_access_token,
    decode_access_token,
    generate_one_time_token,
    hash_one_time_token,
    hash_password,
    validate_password_strength,
    verify_one_time_token,
    verify_password,
)
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
from app.infrastructure.persistence.repositories.preferences_repository import PreferencesRepository
from app.infrastructure.persistence.repositories.users_repository import UsersRepository


class AuthService:
    def __init__(
        self,
        users_repository: UsersRepository,
        preferences_repository: PreferencesRepository,
        settings: Settings,
    ):
        self.users_repository = users_repository
        self.preferences_repository = preferences_repository
        self.settings = settings

    @staticmethod
    def _normalize_email(email: str) -> str:
        return email.strip().lower()

    @staticmethod
    def _split_display_name(display_name: str) -> tuple[str | None, str | None]:
        parts = display_name.strip().split()
        if not parts:
            return None, None
        if len(parts) == 1:
            return parts[0], None
        return parts[0], ' '.join(parts[1:])

    @staticmethod
    def _now() -> datetime:
        return datetime.now(timezone.utc)

    @staticmethod
    def _expires_at_is_invalid(requested_at: datetime | None, expires_in_seconds: int) -> bool:
        if requested_at is None:
            return True
        return (AuthService._now() - requested_at).total_seconds() > expires_in_seconds

    def _preview_token(self, token: str | None) -> str | None:
        if token is None or not self.settings.allows_sensitive_token_previews:
            return None
        return token

    def _build_challenge_response(
        self,
        *,
        detail: str,
        preview_token: str | None = None,
        expires_in: int | None = None,
    ) -> AuthChallengeRead:
        return AuthChallengeRead(
            detail=detail,
            preview_token=self._preview_token(preview_token),
            expires_in=expires_in,
        )

    async def _get_or_create_preferences(self, user_id: UUID):
        preference = await self.preferences_repository.get_for_user(user_id)
        if preference is None:
            preference = self.preferences_repository.create_for_user(user_id=user_id)
            await self.preferences_repository.commit()
            await self.preferences_repository.refresh(preference)
        return preference

    async def _build_session_for_user(self, user: User) -> AuthSessionRead:
        current_user = await self.users_repository.get_user_with_profile(user.id)
        if current_user is None or not current_user.is_active:
            raise PermissionError('authenticated_user_not_found')

        preference = await self._get_or_create_preferences(current_user.id)
        return AuthSessionRead(
            user=current_user,
            onboarding_completed=preference.onboarding_completed,
        )

    async def _build_token_response_for_user(self, user: User) -> AuthTokenRead:
        session = await self._build_session_for_user(user)
        expires_in = self.settings.auth_access_token_expire_seconds
        access_token = create_access_token(
            subject=str(user.id),
            secret_key=self.settings.auth_secret_key,
            expires_in_seconds=expires_in,
            additional_claims={'ver': user.auth_token_version},
        )
        return AuthTokenRead(
            access_token=access_token,
            expires_in=expires_in,
            session=session,
        )

    def _validate_new_password(self, password: str) -> None:
        validate_password_strength(password)

    async def signup(self, payload: AuthSignupRequest) -> AuthTokenRead:
        email = self._normalize_email(payload.email)
        existing_user = await self.users_repository.get_by_email(email)
        if existing_user is not None:
            raise ValueError('email_already_in_use')

        try:
            self._validate_new_password(payload.password)
        except WeakPasswordError as error:
            raise ValueError(str(error)) from error

        user = self.users_repository.create_user(
            email=email,
            password_hash=hash_password(payload.password),
        )
        await self.users_repository.flush()

        trimmed_display_name = payload.display_name.strip()
        first_name, last_name = self._split_display_name(trimmed_display_name)
        self.users_repository.create_profile(
            user_id=user.id,
            display_name=trimmed_display_name,
            first_name=first_name,
            last_name=last_name,
        )
        self.preferences_repository.create_for_user(
            user_id=user.id,
            onboarding_completed=False,
        )
        await self.users_repository.commit()
        return await self._build_token_response_for_user(user)

    async def login(self, payload: AuthLoginRequest) -> AuthTokenRead:
        email = self._normalize_email(payload.email)
        user = await self.users_repository.get_by_email(email)
        if user is None or not user.is_active:
            raise PermissionError('invalid_credentials')
        try:
            is_valid_password = verify_password(payload.password, user.password_hash)
        except Exception as error:
            raise PermissionError('invalid_credentials') from error
        if not is_valid_password:
            raise PermissionError('invalid_credentials')
        return await self._build_token_response_for_user(user)

    async def request_password_reset(self, payload: AuthPasswordResetRequest) -> AuthChallengeRead:
        email = self._normalize_email(payload.email)
        user = await self.users_repository.get_by_email(email)
        preview_token: str | None = None

        if user is not None and user.is_active and user.password_hash:
            preview_token = generate_one_time_token()
            user.password_reset_token_hash = hash_one_time_token(preview_token)
            user.password_reset_requested_at = self._now()
            await self.users_repository.commit()

        return self._build_challenge_response(
            detail='If that account exists, password reset instructions are ready.',
            preview_token=preview_token,
            expires_in=self.settings.auth_password_reset_token_expire_seconds,
        )

    async def reset_password(self, payload: AuthPasswordResetConfirmRequest) -> AuthTokenRead:
        try:
            self._validate_new_password(payload.new_password)
        except WeakPasswordError as error:
            raise ValueError(str(error)) from error

        token_hash = hash_one_time_token(payload.token)
        user = await self.users_repository.get_by_password_reset_token_hash(token_hash)
        if user is None or not user.is_active:
            raise PermissionError('invalid_password_reset_token')
        if not verify_one_time_token(payload.token, user.password_reset_token_hash):
            raise PermissionError('invalid_password_reset_token')
        if self._expires_at_is_invalid(
            user.password_reset_requested_at,
            self.settings.auth_password_reset_token_expire_seconds,
        ):
            user.password_reset_token_hash = None
            user.password_reset_requested_at = None
            await self.users_repository.commit()
            raise PermissionError('password_reset_token_expired')

        user.password_hash = hash_password(payload.new_password)
        user.password_reset_token_hash = None
        user.password_reset_requested_at = None
        user.auth_token_version += 1
        await self.users_repository.commit()
        return await self._build_token_response_for_user(user)

    async def request_email_verification(self, user: User) -> AuthChallengeRead:
        if user.email_verified:
            return self._build_challenge_response(
                detail='Your email address is already verified.',
            )

        preview_token = generate_one_time_token()
        user.email_verification_token_hash = hash_one_time_token(preview_token)
        user.email_verification_requested_at = self._now()
        await self.users_repository.commit()
        return self._build_challenge_response(
            detail='Email verification instructions are ready.',
            preview_token=preview_token,
            expires_in=self.settings.auth_email_verification_token_expire_seconds,
        )

    async def confirm_email_verification(
        self,
        payload: AuthEmailVerificationConfirmRequest,
    ) -> AuthMessageRead:
        token_hash = hash_one_time_token(payload.token)
        user = await self.users_repository.get_by_email_verification_token_hash(token_hash)
        if user is None or not user.is_active:
            raise PermissionError('invalid_email_verification_token')
        if not verify_one_time_token(payload.token, user.email_verification_token_hash):
            raise PermissionError('invalid_email_verification_token')
        if self._expires_at_is_invalid(
            user.email_verification_requested_at,
            self.settings.auth_email_verification_token_expire_seconds,
        ):
            user.email_verification_token_hash = None
            user.email_verification_requested_at = None
            await self.users_repository.commit()
            raise PermissionError('email_verification_token_expired')

        user.email_verified_at = self._now()
        user.email_verification_token_hash = None
        user.email_verification_requested_at = None
        await self.users_repository.commit()
        return AuthMessageRead(detail='Email address verified.')

    async def get_current_session(self, user: User) -> AuthSessionRead:
        return await self._build_session_for_user(user)

    async def get_authenticated_user(self, token: str) -> User:
        try:
            payload = decode_access_token(
                token,
                secret_key=self.settings.auth_secret_key,
            )
        except Exception as error:
            raise PermissionError('invalid_access_token') from error

        subject = payload.get('sub')
        if not isinstance(subject, str) or not subject.strip():
            raise PermissionError('invalid_access_token')

        try:
            user_id = UUID(subject)
        except ValueError as error:
            raise PermissionError('invalid_access_token') from error

        user = await self.users_repository.get_user_with_profile(user_id)
        if user is None or not user.is_active:
            raise PermissionError('invalid_access_token')

        token_version = payload.get('ver', 1)
        if not isinstance(token_version, int) or token_version < 1:
            raise PermissionError('invalid_access_token')
        if token_version != user.auth_token_version:
            raise PermissionError('invalid_access_token')

        return user
