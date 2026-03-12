from decimal import Decimal
from uuid import UUID

from app.domain.goals.models import Goal
from app.domain.progress.models import MeasurementLog, WeightLog
from app.domain.progress.schemas import (
    LatestMeasurementSummaryRead,
    MeasurementLogCreateRequest,
    MeasurementLogListRead,
    MeasurementLogRead,
    ProgressGoalSummaryRead,
    ProgressOverviewRead,
    WeightLogCreateRequest,
    WeightLogListRead,
    WeightLogRead,
)
from app.infrastructure.persistence.repositories.goals_repository import GoalsRepository
from app.infrastructure.persistence.repositories.progress_repository import ProgressRepository

_ZERO = Decimal('0.00')
_QUANTIZER = Decimal('0.01')


class ProgressService:
    def __init__(
        self,
        progress_repository: ProgressRepository,
        goals_repository: GoalsRepository,
    ):
        self.progress_repository = progress_repository
        self.goals_repository = goals_repository

    @staticmethod
    def _quantize(value: Decimal | None) -> Decimal | None:
        if value is None:
            return None
        return value.quantize(_QUANTIZER)

    @staticmethod
    def _normalized_text(value: str | None) -> str:
        return (value or '').strip()

    def _build_goal_summary(self, goal: Goal | None) -> ProgressGoalSummaryRead | None:
        if goal is None:
            return None
        return ProgressGoalSummaryRead(
            id=goal.id,
            code=goal.code,
            title=goal.title,
            target_value=self._quantize(goal.target_value),
            target_unit=goal.target_unit,
        )

    def _build_latest_measurement_summary(
        self,
        logs: list[MeasurementLog],
    ) -> list[LatestMeasurementSummaryRead]:
        latest_by_type: dict[str, LatestMeasurementSummaryRead] = {}
        for log in logs:
            measurement_type = self._normalized_text(log.measurement_type).lower()
            if not measurement_type or measurement_type in latest_by_type:
                continue
            latest_by_type[measurement_type] = LatestMeasurementSummaryRead(
                measurement_type=log.measurement_type,
                measured_at=log.measured_at,
                value=self._quantize(log.value) or _ZERO,
                unit=log.unit,
            )
        return list(latest_by_type.values())

    def _build_weight_read(self, log: WeightLog) -> WeightLogRead:
        return WeightLogRead.model_validate(log)

    def _build_measurement_read(self, log: MeasurementLog) -> MeasurementLogRead:
        return MeasurementLogRead.model_validate(log)

    async def get_overview(self, user_id: UUID) -> ProgressOverviewRead:
        weight_logs = await self.progress_repository.list_weight_logs(user_id, limit=2)
        measurement_logs = await self.progress_repository.list_measurement_logs(user_id)
        current_goal = await self.goals_repository.get_current_for_user(user_id)

        latest_weight = weight_logs[0] if weight_logs else None
        previous_weight = weight_logs[1] if len(weight_logs) > 1 else None
        weight_change = None
        weight_change_unit = None
        if latest_weight is not None and previous_weight is not None:
            latest_unit = self._normalized_text(latest_weight.unit).lower()
            previous_unit = self._normalized_text(previous_weight.unit).lower()
            if latest_unit and latest_unit == previous_unit:
                weight_change = self._quantize(latest_weight.weight - previous_weight.weight)
                weight_change_unit = latest_weight.unit

        return ProgressOverviewRead(
            latest_weight=None if latest_weight is None else self._build_weight_read(latest_weight),
            previous_weight=None
            if previous_weight is None
            else self._build_weight_read(previous_weight),
            weight_change=weight_change,
            weight_change_unit=weight_change_unit,
            latest_measurements=self._build_latest_measurement_summary(measurement_logs),
            current_goal=self._build_goal_summary(current_goal),
        )

    async def list_weight_logs(self, user_id: UUID) -> WeightLogListRead:
        logs = await self.progress_repository.list_weight_logs(user_id)
        return WeightLogListRead(items=[self._build_weight_read(log) for log in logs])

    async def create_weight_log(
        self,
        user_id: UUID,
        payload: WeightLogCreateRequest,
    ) -> WeightLogRead:
        entry = self.progress_repository.create_weight_log(
            user_id=user_id,
            measured_at=payload.measured_at,
            weight=self._quantize(payload.weight) or _ZERO,
            unit=self._normalized_text(payload.unit) or 'kg',
            note=payload.note,
        )
        await self.progress_repository.commit()
        await self.progress_repository.refresh(entry)
        return self._build_weight_read(entry)

    async def list_measurement_logs(self, user_id: UUID) -> MeasurementLogListRead:
        logs = await self.progress_repository.list_measurement_logs(user_id)
        return MeasurementLogListRead(
            items=[self._build_measurement_read(log) for log in logs]
        )

    async def create_measurement_log(
        self,
        user_id: UUID,
        payload: MeasurementLogCreateRequest,
    ) -> MeasurementLogRead:
        entry = self.progress_repository.create_measurement_log(
            user_id=user_id,
            measurement_type=self._normalized_text(payload.measurement_type),
            measured_at=payload.measured_at,
            value=self._quantize(payload.value) or _ZERO,
            unit=self._normalized_text(payload.unit),
            note=payload.note,
        )
        await self.progress_repository.commit()
        await self.progress_repository.refresh(entry)
        return self._build_measurement_read(entry)
