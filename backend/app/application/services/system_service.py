from urllib.parse import urlparse

from app.core.config import Settings
from app.domain.system.schemas import (
    DatabaseFoundation,
    FoundationResource,
    SystemFoundationResponse,
)


class SystemService:
    def __init__(self, settings: Settings):
        self.settings = settings

    def get_foundation_summary(self) -> SystemFoundationResponse:
        parsed = urlparse(self.settings.database_url)

        return SystemFoundationResponse(
            service=self.settings.app_name,
            version=self.settings.app_version,
            environment=self.settings.environment,
            api_prefix=self.settings.api_v1_prefix,
            database=DatabaseFoundation(
                driver=parsed.scheme or "unknown",
                migrations="alembic configured",
                url_configured=bool(self.settings.database_url),
            ),
            resources=[
                FoundationResource(
                    name="users",
                    status="scaffolded",
                    notes="Initial models, schemas, repositories, and services are in place.",
                ),
                FoundationResource(
                    name="nutrition",
                    status="scaffolded",
                    notes="Foods, nutrients, meals, and meal entries are modeled without calculations.",
                ),
                FoundationResource(
                    name="progress",
                    status="scaffolded",
                    notes="Weight and measurement logs are modeled without analytics.",
                ),
            ],
        )