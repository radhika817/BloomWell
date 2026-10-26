"""0003_prerequisite_tables

Revision ID: 0003_prerequisite_tables
Revises: 0002_checkins_and_journal
Create Date: 2026-10-26 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '0003_prerequisite_tables'
down_revision: Union[str, None] = '0002_checkins_and_journal'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add cycle tracking preference columns
    op.add_column(
        'user_preferences',
        sa.Column('cycle_tracking_enabled', sa.Boolean(), server_default=sa.text('false'), nullable=False),
    )
    op.add_column(
        'user_preferences',
        sa.Column('cycle_tracking_consent_at', sa.DateTime(timezone=True), nullable=True),
    )

    # 2. academic_events table
    op.create_table(
        'academic_events',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('title', sa.String(length=120), nullable=False),
        sa.Column('event_date', sa.Date(), nullable=False),
        sa.Column('event_type', sa.String(length=50), server_default='exam', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_academic_events_user_id', 'academic_events', ['user_id'])
    op.create_index('ix_academic_events_user_id_event_date', 'academic_events', ['user_id', 'event_date'])

    # 3. activities table
    op.create_table(
        'activities',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('title', sa.String(length=150), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('duration_minutes', sa.Integer(), server_default='5', nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('language', sa.String(length=10), server_default='en', nullable=False),
        sa.Column('source', sa.String(length=255), nullable=True),
        sa.Column('is_published', sa.Boolean(), server_default=sa.text('true'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_activities_category', 'activities', ['category'])
    op.create_index('ix_activities_is_published', 'activities', ['is_published'])

    # 4. user_activity_logs table
    op.create_table(
        'user_activity_logs',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('activity_id', sa.UUID(as_uuid=True), sa.ForeignKey('activities.id', ondelete='CASCADE'), nullable=False),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('helpfulness_rating', sa.Integer(), nullable=True),
        sa.Column('is_favorite', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_user_activity_logs_user_id', 'user_activity_logs', ['user_id'])
    op.create_index('ix_user_activity_logs_user_id_activity_id', 'user_activity_logs', ['user_id', 'activity_id'])

    # 5. cycle_logs table
    op.create_table(
        'cycle_logs',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('period_start', sa.Date(), nullable=False),
        sa.Column('period_end', sa.Date(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_cycle_logs_user_id_period_start', 'cycle_logs', ['user_id', 'period_start'])


def downgrade() -> None:
    op.drop_table('cycle_logs')
    op.drop_table('user_activity_logs')
    op.drop_table('activities')
    op.drop_table('academic_events')
    op.drop_column('user_preferences', 'cycle_tracking_consent_at')
    op.drop_column('user_preferences', 'cycle_tracking_enabled')
