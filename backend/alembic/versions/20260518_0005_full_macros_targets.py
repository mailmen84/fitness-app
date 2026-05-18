"""Add carbs and fat target columns on preferences table.

Revision ID: 20260518_0005
Revises: 20260518_0004
Create Date: 2026-05-18 00:00:00
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '20260518_0005'
down_revision = '20260518_0004'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'preferences',
        sa.Column('daily_carbs_target', sa.Numeric(10, 2), nullable=True),
    )
    op.add_column(
        'preferences',
        sa.Column('daily_fat_target', sa.Numeric(10, 2), nullable=True),
    )


def downgrade() -> None:
    op.drop_column('preferences', 'daily_fat_target')
    op.drop_column('preferences', 'daily_carbs_target')
