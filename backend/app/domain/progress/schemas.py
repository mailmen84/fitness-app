from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import Field

from app.domain.shared.schemas import DomainSchema, TimestampedReadSchema


class WeightLogCreate(DomainSchema):
    user_id: UUID
    measured_at: datetime
    weight: Decimal
    unit: str = 'kg'
    note: str | None = None


class WeightLogUpdate(DomainSchema):
    measured_at: datetime | None = None
    weight: Decimal | None = None
    unit: str | None = None
    note: str | None = None


class WeightLogRead(TimestampedReadSchema):
    user_id: UUID
    measured_at: datetime
    weight: Decimal
    unit: str
    note: str | None = None


class WeightLogCreateRequest(DomainSchema):
    measured_at: datetime
    weight: Decimal = Field(gt=0)
    unit: str = Field(default='kg', min_length=1)
    note: str | None = None


class WeightLogListRead(DomainSchema):
    items: list[WeightLogRead] = Field(default_factory=list)


class MeasurementLogCreate(DomainSchema):
    user_id: UUID
    measurement_type: str
    measured_at: datetime
    value: Decimal
    unit: str
    note: str | None = None


class MeasurementLogUpdate(DomainSchema):
    measurement_type: str | None = None
    measured_at: datetime | None = None
    value: Decimal | None = None
    unit: str | None = None
    note: str | None = None


class MeasurementLogRead(TimestampedReadSchema):
    user_id: UUID
    measurement_type: str
    measured_at: datetime
    value: Decimal
    unit: str
    note: str | None = None


class MeasurementLogCreateRequest(DomainSchema):
    measurement_type: str = Field(min_length=1)
    measured_at: datetime
    value: Decimal = Field(gt=0)
    unit: str = Field(min_length=1)
    note: str | None = None


class MeasurementLogListRead(DomainSchema):
    items: list[MeasurementLogRead] = Field(default_factory=list)


class ProgressGoalSummaryRead(DomainSchema):
    id: UUID
    code: str
    title: str
    target_value: Decimal | None = None
    target_unit: str | None = None


class LatestMeasurementSummaryRead(DomainSchema):
    measurement_type: str
    measured_at: datetime
    value: Decimal
    unit: str


class ProgressOverviewRead(DomainSchema):
    latest_weight: WeightLogRead | None = None
    previous_weight: WeightLogRead | None = None
    weight_change: Decimal | None = None
    weight_change_unit: str | None = None
    latest_measurements: list[LatestMeasurementSummaryRead] = Field(default_factory=list)
    current_goal: ProgressGoalSummaryRead | None = None
