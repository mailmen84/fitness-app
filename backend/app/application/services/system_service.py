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
                driver=parsed.scheme or 'unknown',
                migrations='alembic configured',
                url_configured=bool(self.settings.database_url),
            ),
            resources=[
                FoundationResource(
                    name='auth',
                    status='active',
                    notes='Signup, login, bearer tokens, password reset foundations, and current-session restore support the authenticated MVP.',
                ),
                FoundationResource(
                    name='users',
                    status='working_mvp',
                    notes='Authenticated current-user reads and profile editing are active.',
                ),
                FoundationResource(
                    name='nutrition',
                    status='working_mvp',
                    notes='Food search uses a small seeded demo dataset and nutrition summaries read logged meals.',
                ),
                FoundationResource(
                    name='progress',
                    status='working_mvp',
                    notes='Weight and measurement logging are active for the authenticated user.',
                ),
            ],
        )

