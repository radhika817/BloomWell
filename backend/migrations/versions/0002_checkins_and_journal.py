"""0002_checkins_and_journal

Revision ID: 0002_checkins_and_journal
Revises: 0001_initial_tables
Create Date: 2026-10-18 16:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0002_checkins_and_journal'
down_revision: Union[str, None] = '0001_initial_tables'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. mood_checkins table
    tags_type = postgresql.ARRAY(sa.String(length=24)).with_variant(sa.JSON(), 'sqlite')

    op.create_table(
        'mood_checkins',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('client_id', sa.UUID(as_uuid=True), nullable=False),
        sa.Column('local_date', sa.Date(), nullable=False),
        sa.Column('mood_score', sa.Integer(), nullable=False),
        sa.Column('stress_score', sa.Integer(), nullable=False),
        sa.Column('energy_score', sa.Integer(), nullable=False),
        sa.Column('sleep_quality_score', sa.Integer(), nullable=True),
        sa.Column('mood_label', sa.String(length=20), nullable=True),
        sa.Column('tags', tags_type, nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint('mood_score >= 1 AND mood_score <= 5', name='ck_checkins_mood_score'),
        sa.CheckConstraint('stress_score >= 1 AND stress_score <= 5', name='ck_checkins_stress_score'),
        sa.CheckConstraint('energy_score >= 1 AND energy_score <= 5', name='ck_checkins_energy_score'),
        sa.CheckConstraint('sleep_quality_score IS NULL OR (sleep_quality_score >= 1 AND sleep_quality_score <= 5)', name='ck_checkins_sleep_score'),
    )
    op.create_unique_constraint('uq_mood_checkins_user_client', 'mood_checkins', ['user_id', 'client_id'])
    op.create_index('ix_mood_checkins_user_id_local_date', 'mood_checkins', ['user_id', 'local_date'])
    op.create_index('ix_mood_checkins_user_id_created_at', 'mood_checkins', ['user_id', 'created_at'])

    # 2. journal_entries table
    op.create_table(
        'journal_entries',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('client_id', sa.UUID(as_uuid=True), nullable=False),
        sa.Column('title', sa.String(length=120), nullable=True),
        sa.Column('body', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_unique_constraint('uq_journal_entries_user_client', 'journal_entries', ['user_id', 'client_id'])
    op.create_index('ix_journal_entries_user_id_created_at', 'journal_entries', ['user_id', 'created_at'])


def downgrade() -> None:
    op.drop_table('journal_entries')
    op.drop_table('mood_checkins')
