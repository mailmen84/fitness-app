"""Add barcode field on foods table.

Revision ID: 20260518_0004
Revises: 20260312_0003
Create Date: 2026-05-18 00:00:00
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '20260518_0004'
down_revision = '20260312_0003'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'foods',
        sa.Column('barcode', sa.String(length=32), nullable=True),
    )
    # Partial unique index so multiple NULL barcodes coexist (Postgres).
    op.create_index(
        'ix_foods_barcode_unique',
        'foods',
        ['barcode'],
        unique=True,
        postgresql_where=sa.text('barcode IS NOT NULL'),
    )


def downgrade() -> None:
    op.drop_index('ix_foods_barcode_unique', table_name='foods')
    op.drop_column('foods', 'barcode')
