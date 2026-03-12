from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class WeightLog(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "weight_logs"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    measured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
    weight: Mapped[Decimal] = mapped_column(Numeric(6, 2), nullable=False)
    unit: Mapped[str] = mapped_column(String(16), default="kg", nullable=False)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    user: Mapped[User] = relationship("User", back_populates="weight_logs")


class MeasurementLog(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "measurement_logs"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    measurement_type: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    measured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
    value: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    unit: Mapped[str] = mapped_column(String(16), nullable=False)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    user: Mapped[User] = relationship("User", back_populates="measurement_logs")


from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.domain.users.models import User