"""Add monthly_covers table and month_year column to sticky_notes

Revision ID: 0002_add_monthly_covers
Revises: 0001_initial_schema
Create Date: 2026-09-22 11:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '0002_add_monthly_covers'
down_revision = '0001_initial_schema'
branch_labels = None
depends_on = None


def upgrade():
    # 1. Agregar columna month_year en sticky_notes para segmentación mensual
    with op.batch_alter_table('sticky_notes', schema=None) as batch_op:
        batch_op.add_column(sa.Column('month_year', sa.String(length=7), nullable=True))
        batch_op.create_index(batch_op.f('ix_sticky_notes_month_year'), ['month_year'], unique=False)

    # 2. Crear tabla monthly_covers (completamente vacía, sin datos iniciales)
    op.create_table('monthly_covers',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('month_year', sa.String(length=7), nullable=False),
        sa.Column('title', sa.String(length=100), nullable=False, server_default=''),
        sa.Column('subtitle', sa.String(length=200), nullable=False, server_default=''),
        sa.Column('year_text', sa.String(length=10), nullable=False, server_default=''),
        sa.Column('background_type', sa.String(length=50), nullable=False, server_default='grid'),
        sa.Column('background_color', sa.String(length=30), nullable=False, server_default='#FFFFFF'),
        sa.Column('design_data', sa.Text(), nullable=False, server_default='[]'),
        sa.Column('is_custom', sa.Boolean(), nullable=True, server_default=sa.false()),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'month_year', name='uq_user_month_cover')
    )
    with op.batch_alter_table('monthly_covers', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_monthly_covers_user_id'), ['user_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_monthly_covers_month_year'), ['month_year'], unique=False)


def downgrade():
    with op.batch_alter_table('monthly_covers', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_monthly_covers_month_year'))
        batch_op.drop_index(batch_op.f('ix_monthly_covers_user_id'))
    op.drop_table('monthly_covers')

    with op.batch_alter_table('sticky_notes', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_sticky_notes_month_year'))
        batch_op.drop_column('month_year')
