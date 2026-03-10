from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    environment: str = 'development'
    host: str = '0.0.0.0'
    port: int = 8000
    api_v1_prefix: str = '/api/v1'
    database_url: str = 'postgresql+asyncpg://fitness_user:fitness_password@localhost:5432/fitness_app'

    model_config = SettingsConfigDict(
        env_prefix='BACKEND_',
        extra='ignore',
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
