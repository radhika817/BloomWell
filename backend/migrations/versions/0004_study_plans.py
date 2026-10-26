"""0004_study_plans

Revision ID: 0004_study_plans
Revises: 0003_prerequisite_tables
Create Date: 2026-10-26 11:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0004_study_plans'
down_revision: Union[str, None] = '0003_prerequisite_tables'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    reason_codes_type = postgresql.ARRAY(sa.String(length=64)).with_variant(sa.JSON(), 'sqlite')

    # 1. study_plans table
    op.create_table(
        'study_plans',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('week_start', sa.Date(), nullable=False),
        sa.Column('days', sa.Integer(), server_default='7', nullable=False),
        sa.Column('mode', sa.String(length=20), server_default='default', nullable=False),
        sa.Column('uses_cycle_data', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('checkin_days_used', sa.Integer(), server_default='0', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("mode IN ('default', 'personalized')", name='ck_study_plans_mode'),
    )
    op.create_unique_constraint('uq_study_plans_user_week_start', 'study_plans', ['user_id', 'week_start'])
    op.create_index('ix_study_plans_user_id_week_start', 'study_plans', ['user_id', 'week_start'])

    # 2. study_plan_items table
    op.create_table(
        'study_plan_items',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('study_plan_id', sa.UUID(as_uuid=True), sa.ForeignKey('study_plans.id', ondelete='CASCADE'), nullable=False),
        sa.Column('plan_date', sa.Date(), nullable=False),
        sa.Column('suggested_load', sa.String(length=20), server_default='normal', nullable=False),
        sa.Column('reason_codes', reason_codes_type, nullable=False),
        sa.Column('academic_event_id', sa.UUID(as_uuid=True), sa.ForeignKey('academic_events.id', ondelete='SET NULL'), nullable=True),
        sa.Column('activity_id', sa.UUID(as_uuid=True), sa.ForeignKey('activities.id', ondelete='SET NULL'), nullable=True),
        sa.Column('status', sa.String(length=20), server_default='suggested', nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("suggested_load IN ('light', 'normal', 'focus')", name='ck_study_plan_items_load'),
        sa.CheckConstraint("status IN ('suggested', 'accepted', 'edited', 'skipped')", name='ck_study_plan_items_status'),
    )
    op.create_unique_constraint('uq_study_plan_items_plan_date', 'study_plan_items', ['study_plan_id', 'plan_date'])
    op.create_index('ix_study_plan_items_study_plan_id', 'study_plan_items', ['study_plan_id'])
    op.create_index('ix_study_plan_items_plan_date', 'study_plan_items', ['plan_date'])


def downgrade() -> None:
    op.drop_table('study_plan_items')
    op.drop_table('study_plans')
