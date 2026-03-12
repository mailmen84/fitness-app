import logging
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.types import Receive, Scope, Send

from app.api.v1.router import api_router
from app.core.config import Settings, get_settings
from app.infrastructure.persistence.database import dispose_engine

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    logger.info('Starting backend in %s mode.', settings.environment)
    yield
    await dispose_engine()


class CORSWrappedApplication:
    def __init__(self, fastapi_app: FastAPI, settings: Settings) -> None:
        self.fastapi_app = fastapi_app
        self._cors_app = CORSMiddleware(
            app=fastapi_app,
            allow_origins=settings.cors_allowed_origins,
            allow_origin_regex=settings.cors_allow_origin_regex or None,
            allow_credentials=settings.cors_allow_credentials,
            allow_methods=['*'],
            allow_headers=['*'],
        )

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        await self._cors_app(scope, receive, send)

    def __getattr__(self, name: str) -> Any:
        return getattr(self.fastapi_app, name)


def create_fastapi_application() -> FastAPI:
    settings = get_settings()

    application = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        docs_url='/docs' if settings.docs_enabled else None,
        openapi_url='/openapi.json' if settings.docs_enabled else None,
        redoc_url='/redoc' if settings.docs_enabled else None,
        lifespan=lifespan,
    )
    application.include_router(api_router, prefix=settings.api_v1_prefix)
    return application


def create_application() -> CORSWrappedApplication:
    settings = get_settings()
    fastapi_app = create_fastapi_application()
    return CORSWrappedApplication(fastapi_app, settings)


app = create_application()