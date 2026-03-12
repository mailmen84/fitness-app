from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import select

from app.domain.progress.models import MeasurementLog, WeightLog
from app.infrastructure.persistence.repositories.base_repository import BaseRepository


class ProgressRepository(BaseRepository):
    async def list_weight_logs(self, user_id: UUID, limit: int | None = None) -> list[WeightLog]:
        statement = (
            select(WeightLog)
            .where(WeightLog.user_id == user_id)
            .order_by(WeightLog.measured_at.desc(), WeightLog.created_at.desc())
        )
        if limit is not None:
            statement = statement.limit(limit)
        result = await self.session.scalars(statement)
        return list(result)

    def create_weight_log(
        self,
        *,
        user_id: UUID,
        measured_at: datetime,
        weight: Decimal,
        unit: str,
        note: str | None,
    ) -> WeightLog:
        entry = WeightLog(
            user_id=user_id,
            measured_at=measured_at,
            weight=weight,
            unit=unit,
            note=note,
        )
        self.add(entry)
        return entry

    async def list_measurement_logs(
        self,
        user_id: UUID,
        limit: int | None = None,
    ) -> list[MeasurementLog]:
        statement = (
            select(MeasurementLog)
            .where(MeasurementLog.user_id == user_id)
            .order_by(MeasurementLog.measured_at.desc(), MeasurementLog.created_at.desc())
        )
        if limit is not None:
            statement = statement.limit(limit)
        result = await self.session.scalars(statement)
        return list(result)

    def create_measurement_log(
        self,
        *,
        user_id: UUID,
        measurement_type: str,
        measured_at: datetime,
        value: Decimal,
        unit: str,
        note: str | None,
    ) -> MeasurementLog:
        entry = MeasurementLog(
            user_id=user_id,
            measurement_type=measurement_type,
            measured_at=measured_at,
            value=value,
            unit=unit,
            note=note,
        )
        self.add(entry)
        return entry
