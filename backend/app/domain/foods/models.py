from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import Boolean, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Food(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "foods"

    name: Mapped[str] = mapped_column(String(160), index=True, nullable=False)
    brand: Mapped[str | None] = mapped_column(String(160), nullable=True)
    barcode: Mapped[str | None] = mapped_column(String(32), nullable=True)
    default_serving_amount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    default_serving_unit: Mapped[str | None] = mapped_column(String(32), nullable=True)
    source: Mapped[str] = mapped_column(String(32), default="internal", nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    nutrients: Mapped[list[FoodNutrient]] = relationship(
        "FoodNutrient",
        back_populates="food",
        cascade="all, delete-orphan",
    )
    meal_entries: Mapped[list[MealEntry]] = relationship("MealEntry", back_populates="food")


class FoodNutrient(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "food_nutrients"

    food_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("foods.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    nutrient_code: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    nutrient_name: Mapped[str] = mapped_column(String(120), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    unit: Mapped[str] = mapped_column(String(32), nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    food: Mapped[Food] = relationship("Food", back_populates="nutrients")


from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.domain.meals.models import MealEntry