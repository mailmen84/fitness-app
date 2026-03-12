"""Persist meal-entry nutrition snapshots.

Revision ID: 20260310_0002
Revises: 20260310_0001
Create Date: 2026-03-10 00:30:00
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '20260310_0002'
down_revision = '20260310_0001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'meal_entries',
        sa.Column('food_name', sa.String(length=160), nullable=False, server_default=sa.text("''")),
    )
    op.add_column(
        'meal_entries',
        sa.Column('calories_total', sa.Numeric(10, 2), nullable=False, server_default=sa.text('0')),
    )
    op.add_column(
        'meal_entries',
        sa.Column('protein_total', sa.Numeric(10, 2), nullable=False, server_default=sa.text('0')),
    )
    op.add_column(
        'meal_entries',
        sa.Column('carbs_total', sa.Numeric(10, 2), nullable=False, server_default=sa.text('0')),
    )
    op.add_column(
        'meal_entries',
        sa.Column('fat_total', sa.Numeric(10, 2), nullable=False, server_default=sa.text('0')),
    )


def downgrade() -> None:
    op.drop_column('meal_entries', 'fat_total')
    op.drop_column('meal_entries', 'carbs_total')
    op.drop_column('meal_entries', 'protein_total')
    op.drop_column('meal_entries', 'calories_total')
    op.drop_column('meal_entries', 'food_name')
