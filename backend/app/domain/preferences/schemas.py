from decimal import Decimal
from uuid import UUID

from app.domain.shared.schemas import DomainSchema, TimestampedReadSchema


class PreferenceCreate(DomainSchema):
    user_id: UUID
    unit_system: str = 'metric'
    timezone: str = 'UTC'
    week_starts_on: str = 'monday'
    daily_calorie_target: Decimal | None = None
    daily_protein_target: Decimal | None = None
    daily_carbs_target: Decimal | None = None
    daily_fat_target: Decimal | None = None
    onboarding_completed: bool = False


class PreferenceUpdate(DomainSchema):
    unit_system: str | None = None
    timezone: str | None = None
    week_starts_on: str | None = None
    daily_calorie_target: Decimal | None = None
    daily_protein_target: Decimal | None = None
    daily_carbs_target: Decimal | None = None
    daily_fat_target: Decimal | None = None
    onboarding_completed: bool | None = None


class PreferencePutRequest(DomainSchema):
    unit_system: str = 'metric'
    timezone: str = 'UTC'
    week_starts_on: str = 'monday'
    daily_calorie_target: Decimal | None = None
    daily_protein_target: Decimal | None = None
    daily_carbs_target: Decimal | None = None
    daily_fat_target: Decimal | None = None
    onboarding_completed: bool = False


class PreferenceRead(TimestampedReadSchema):
    user_id: UUID
    unit_system: str
    timezone: str
    week_starts_on: str
    daily_calorie_target: Decimal | None = None
    daily_protein_target: Decimal | None = None
    daily_carbs_target: Decimal | None = None
    daily_fat_target: Decimal | None = None
    onboarding_completed: bool
