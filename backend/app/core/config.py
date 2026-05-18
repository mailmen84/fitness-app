from functools import lru_cache

from pydantic import Field, computed_field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_DEFAULT_AUTH_SECRET_KEY = 'development-auth-secret-change-me-before-production-use'
_LOCAL_ENVIRONMENTS = {'development', 'local', 'test'}
_LOCAL_CORS_ALLOWED_ORIGINS = (
    'http://localhost',
    'http://127.0.0.1',
    'http://10.0.2.2',
    'http://10.0.3.2',
)
# 10.0.2.2 is the host loopback alias used by the Android emulator and
# 10.0.3.2 is the equivalent for Genymotion; both must be allowed so the
# Flutter app running inside an emulator can call the local backend.
_LOCAL_CORS_ALLOW_ORIGIN_REGEX = (
    r'^https?://(localhost|127\.0\.0\.1|\[::1\]|10\.0\.2\.2|10\.0\.3\.2)'
    r'(:\d+)?$'
)


class Settings(BaseSettings):
    app_name: str = 'Fitness App API'
    app_version: str = '0.1.0'
    environment: str = 'development'
    host: str = '0.0.0.0'
    port: int = 8000
    docs_enabled: bool = True
    api_v1_prefix: str = '/api/v1'
    database_url: str = (
        'postgresql+asyncpg://fitness_user:fitness_password@localhost:5432/fitness_app'
    )
    alembic_database_url: str | None = None
    database_echo: bool = False
    auth_secret_key: str = _DEFAULT_AUTH_SECRET_KEY
    auth_access_token_expire_seconds: int = Field(default=60 * 60 * 12, gt=60)
    auth_password_reset_token_expire_seconds: int = Field(default=60 * 60, gt=300)
    auth_email_verification_token_expire_seconds: int = Field(default=60 * 60 * 24, gt=300)
    cors_allowed_origins: list[str] = Field(default_factory=list)
    cors_allow_origin_regex: str | None = None
    cors_allow_credentials: bool = True

    model_config = SettingsConfigDict(
        env_prefix='BACKEND_',
        env_file=('.env', '../.env'),
        env_file_encoding='utf-8',
        extra='ignore',
    )

    @field_validator('environment')
    @classmethod
    def _normalize_environment(cls, value: str) -> str:
        normalized = value.strip().lower()
        if not normalized:
            raise ValueError('BACKEND_ENVIRONMENT is required.')
        return normalized

    @field_validator('auth_secret_key')
    @classmethod
    def _validate_auth_secret_key(cls, value: str) -> str:
        normalized = value.strip()
        if len(normalized) < 32:
            raise ValueError('BACKEND_AUTH_SECRET_KEY must be at least 32 characters long.')
        return normalized

    @field_validator('cors_allowed_origins')
    @classmethod
    def _normalize_cors_allowed_origins(cls, value: list[str]) -> list[str]:
        normalized: list[str] = []
        seen: set[str] = set()
        for origin in value:
            trimmed = origin.strip()
            if not trimmed or trimmed in seen:
                continue
            seen.add(trimmed)
            normalized.append(trimmed)
        return normalized

    @field_validator('cors_allow_origin_regex')
    @classmethod
    def _normalize_cors_allow_origin_regex(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = value.strip()
        return normalized or None

    @computed_field
    @property
    def resolved_alembic_database_url(self) -> str:
        if self.alembic_database_url:
            return self.alembic_database_url
        return self.database_url.replace('+asyncpg', '+psycopg')

    @computed_field
    @property
    def is_local_environment(self) -> bool:
        return self.environment in _LOCAL_ENVIRONMENTS

    @computed_field
    @property
    def uses_insecure_default_auth_secret(self) -> bool:
        return self.auth_secret_key == _DEFAULT_AUTH_SECRET_KEY

    @computed_field
    @property
    def resolved_cors_allowed_origins(self) -> list[str]:
        if self.cors_allowed_origins:
            return self.cors_allowed_origins
        if self.is_local_environment:
            return list(_LOCAL_CORS_ALLOWED_ORIGINS)
        return []

    @computed_field
    @property
    def resolved_cors_allow_origin_regex(self) -> str | None:
        if self.cors_allow_origin_regex is not None:
            return self.cors_allow_origin_regex
        if self.is_local_environment:
            return _LOCAL_CORS_ALLOW_ORIGIN_REGEX
        return None

    @computed_field
    @property
    def allows_sensitive_token_previews(self) -> bool:
        return self.is_local_environment


@lru_cache
def get_settings() -> Settings:
    return Settings()
