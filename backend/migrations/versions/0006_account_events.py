"""0006_account_events

Revision ID: 0006_account_events
Revises: 0005_help_hub_and_education
Create Date: 2026-10-31 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0006_account_events'
down_revision: Union[str, None] = '0005_help_hub_and_education'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. account_events table
    op.create_table(
        'account_events',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column(
            'event_type',
            sa.Enum(
                'export_requested',
                'password_changed',
                'sessions_revoked',
                'cycle_data_deleted',
                'consent_changed',
                name='account_event_type',
            ),
            nullable=False,
        ),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index(
        'ix_account_events_user_id_created_at',
        'account_events',
        ['user_id', 'created_at'],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index('ix_account_events_user_id_created_at', table_name='account_events')
    op.drop_table('account_events')
    # Drop enum type in postgres if applicable
    bind = op.get_bind()
    if bind.dialect.name == 'postgresql':
        sa.Enum(name='account_event_type').drop(bind, checkfirst=True)
