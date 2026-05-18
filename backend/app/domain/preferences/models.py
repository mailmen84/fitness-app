from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import Boolean, ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Preference(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "preferences"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    unit_system: Mapped[str] = mapped_column(String(16), default="metric", nullable=False)
    timezone: Mapped[str] = mapped_column(String(64), default="UTC", nullable=False)
    week_starts_on: Mapped[str] = mapped_column(String(16), default="monday", nullable=False)
    daily_calorie_target: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    daily_protein_target: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    daily_carbs_target: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    daily_fat_target: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    onboarding_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    user: Mapped[User] = relationship("User", back_populates="preferences")


from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.domain.users.models import User