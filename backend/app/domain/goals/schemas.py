from datetime import date
from decimal import Decimal
from uuid import UUID

from app.domain.shared.schemas import DomainSchema, TimestampedReadSchema


class GoalCreate(DomainSchema):
    user_id: UUID
    code: str
    title: str
    target_value: Decimal | None = None
    target_unit: str | None = None
    is_active: bool = True
    starts_on: date | None = None
    ends_on: date | None = None
    notes: str | None = None


class GoalUpdate(DomainSchema):
    title: str | None = None
    target_value: Decimal | None = None
    target_unit: str | None = None
    is_active: bool | None = None
    starts_on: date | None = None
    ends_on: date | None = None
    notes: str | None = None


class CurrentGoalPutRequest(DomainSchema):
    code: str
    title: str
    target_value: Decimal | None = None
    target_unit: str | None = None
    starts_on: date | None = None
    ends_on: date | None = None
    notes: str | None = None


class GoalRead(TimestampedReadSchema):
    user_id: UUID
    code: str
    title: str
    target_value: Decimal | None = None
    target_unit: str | None = None
    is_active: bool
    starts_on: date | None = None
    ends_on: date | None = None
    notes: str | None = None