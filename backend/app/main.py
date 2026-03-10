from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.v1.router import api_router
from app.core.config import get_settings


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    print(f'Starting backend in {settings.environment} mode on port {settings.port}.')
    yield


def create_application() -> FastAPI:
    settings = get_settings()

    application = FastAPI(
        title='Fitness App API',
        version='0.1.0',
        docs_url='/docs',
        openapi_url='/openapi.json',
        lifespan=lifespan,
    )
    application.include_router(api_router, prefix=settings.api_v1_prefix)
    return application


app = create_application()

