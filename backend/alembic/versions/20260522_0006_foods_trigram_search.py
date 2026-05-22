"""Enable pg_trgm and add trigram GIN indexes on foods.name and foods.brand.

Revision ID: 20260522_0006
Revises: 20260518_0005
Create Date: 2026-05-22 00:00:00
"""

from alembic import op

# revision identifiers, used by Alembic.
revision = '20260522_0006'
down_revision = '20260518_0005'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # pg_trgm enables trigram similarity operators (% and similarity()).
    op.execute('CREATE EXTENSION IF NOT EXISTS pg_trgm')

    # GIN indexes on name and brand for ILIKE '%word%' and similarity ordering.
    # gin_trgm_ops is the operator class for trigram matching.
    op.execute(
        'CREATE INDEX IF NOT EXISTS ix_foods_name_trgm '
        'ON foods USING gin (name gin_trgm_ops)'
    )
    op.execute(
        'CREATE INDEX IF NOT EXISTS ix_foods_brand_trgm '
        'ON foods USING gin (brand gin_trgm_ops)'
    )


def downgrade() -> None:
    op.execute('DROP INDEX IF EXISTS ix_foods_brand_trgm')
    op.execute('DROP INDEX IF EXISTS ix_foods_name_trgm')
    # We intentionally do NOT drop the extension on downgrade because it may be
    # used by other indexes/queries and dropping it is destructive.
