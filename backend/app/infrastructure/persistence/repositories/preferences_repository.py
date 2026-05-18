from decimal import Decimal
from uuid import UUID

from sqlalchemy import select

from app.domain.preferences.models import Preference
from app.infrastructure.persistence.repositories.base_repository import BaseRepository


class PreferencesRepository(BaseRepository):
    async def get_for_user(self, user_id: UUID) -> Preference | None:
        result = await self.session.execute(
            select(Preference).where(Preference.user_id == user_id)
        )
        return result.scalar_one_or_none()

    def create_for_user(
        self,
        *,
        user_id: UUID,
        unit_system: str = 'metric',
        timezone: str = 'UTC',
        week_starts_on: str = 'monday',
        daily_calorie_target: Decimal | None = None,
        daily_protein_target: Decimal | None = None,
        daily_carbs_target: Decimal | None = None,
        daily_fat_target: Decimal | None = None,
        onboarding_completed: bool = False,
    ) -> Preference:
        preference = Preference(
            user_id=user_id,
            unit_system=unit_system,
            timezone=timezone,
            week_starts_on=week_starts_on,
            daily_calorie_target=daily_calorie_target,
            daily_protein_target=daily_protein_target,
            daily_carbs_target=daily_carbs_target,
            daily_fat_target=daily_fat_target,
            onboarding_completed=onboarding_completed,
        )
        self.add(preference)
        return preference