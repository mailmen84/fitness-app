from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

_ZERO = Decimal('0.00')


class Meal(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = 'meals'

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey('users.id', ondelete='CASCADE'),
        index=True,
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    user: Mapped[User] = relationship('User', back_populates='meals')
    entries: Mapped[list[MealEntry]] = relationship(
        'MealEntry',
        back_populates='meal',
        cascade='all, delete-orphan',
    )


class MealEntry(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = 'meal_entries'

    meal_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey('meals.id', ondelete='CASCADE'),
        index=True,
        nullable=False,
    )
    food_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey('foods.id', ondelete='SET NULL'),
        index=True,
        nullable=True,
    )
    food_name: Mapped[str] = mapped_column(String(160), nullable=False, default='')
    quantity: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    unit: Mapped[str] = mapped_column(String(32), nullable=False)
    calories_total: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False, default=_ZERO)
    protein_total: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False, default=_ZERO)
    carbs_total: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False, default=_ZERO)
    fat_total: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False, default=_ZERO)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    meal: Mapped[Meal] = relationship('Meal', back_populates='entries')
    food: Mapped[Food | None] = relationship('Food', back_populates='meal_entries')


from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.domain.foods.models import Food
    from app.domain.users.models import User
