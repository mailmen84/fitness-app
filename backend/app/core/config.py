from functools import lru_cache

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict

_DEFAULT_AUTH_SECRET_KEY = 'development-auth-secret-change-me-before-production-use'
_LOCAL_CORS_ALLOW_ORIGIN_REGEX = r'^https?://(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$'


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
    auth_access_token_expire_seconds: int = Field(default=60 * 60 * 24 * 7, gt=0)
    cors_allowed_origins: list[str] = Field(
        default_factory=lambda: [
            'http://localhost',
            'http://127.0.0.1',
        ]
    )
    cors_allow_origin_regex: str | None = _LOCAL_CORS_ALLOW_ORIGIN_REGEX
    cors_allow_credentials: bool = True

    model_config = SettingsConfigDict(
        env_prefix='BACKEND_',
        env_file=('.env', '../.env'),
        env_file_encoding='utf-8',
        extra='ignore',
    )

    @computed_field
    @property
    def resolved_alembic_database_url(self) -> str:
        if self.alembic_database_url:
            return self.alembic_database_url
        return self.database_url.replace('+asyncpg', '+psycopg')

    @computed_field
    @property
    def uses_insecure_default_auth_secret(self) -> bool:
        return self.auth_secret_key == _DEFAULT_AUTH_SECRET_KEY


@lru_cache
def get_settings() -> Settings:
    return Settings()
