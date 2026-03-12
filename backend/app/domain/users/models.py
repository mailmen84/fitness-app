from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class User(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = 'users'

    email: Mapped[str] = mapped_column(String(320), unique=True, index=True, nullable=False)
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    auth_token_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    email_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    password_reset_token_hash: Mapped[str | None] = mapped_column(
        String(255),
        index=True,
        nullable=True,
    )
    password_reset_requested_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    email_verification_token_hash: Mapped[str | None] = mapped_column(
        String(255),
        index=True,
        nullable=True,
    )
    email_verification_requested_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    profile: Mapped[UserProfile | None] = relationship(
        'UserProfile',
        back_populates='user',
        uselist=False,
        cascade='all, delete-orphan',
    )
    goals: Mapped[list[Goal]] = relationship(
        'Goal',
        back_populates='user',
        cascade='all, delete-orphan',
    )
    preferences: Mapped[Preference | None] = relationship(
        'Preference',
        back_populates='user',
        uselist=False,
        cascade='all, delete-orphan',
    )
    meals: Mapped[list[Meal]] = relationship(
        'Meal',
        back_populates='user',
        cascade='all, delete-orphan',
    )
    weight_logs: Mapped[list[WeightLog]] = relationship(
        'WeightLog',
        back_populates='user',
        cascade='all, delete-orphan',
    )
    measurement_logs: Mapped[list[MeasurementLog]] = relationship(
        'MeasurementLog',
        back_populates='user',
        cascade='all, delete-orphan',
    )

    @property
    def email_verified(self) -> bool:
        return self.email_verified_at is not None


class UserProfile(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = 'user_profiles'

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey('users.id', ondelete='CASCADE'),
        unique=True,
        index=True,
        nullable=False,
    )
    display_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    first_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    last_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    height_cm: Mapped[Decimal | None] = mapped_column(Numeric(6, 2), nullable=True)
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)

    user: Mapped[User] = relationship('User', back_populates='profile')


from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.domain.goals.models import Goal
    from app.domain.meals.models import Meal
    from app.domain.preferences.models import Preference
    from app.domain.progress.models import MeasurementLog, WeightLog
