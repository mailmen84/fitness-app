from uuid import UUID

from app.core.config import Settings
from app.core.security import create_access_token, decode_access_token, hash_password, verify_password
from app.domain.auth.schemas import AuthLoginRequest, AuthSessionRead, AuthSignupRequest, AuthTokenRead
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
            subject=str(session.user.id),
            secret_key=self.settings.auth_secret_key,
            expires_in_seconds=expires_in,
        )
        return AuthTokenRead(
            access_token=access_token,
            expires_in=expires_in,
            session=session,
        )

    async def signup(self, payload: AuthSignupRequest) -> AuthTokenRead:
        email = self._normalize_email(payload.email)
        existing_user = await self.users_repository.get_by_email(email)
        if existing_user is not None:
            raise ValueError('email_already_in_use')

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
        return user
