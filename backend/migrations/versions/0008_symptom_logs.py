"""0008_symptom_logs

Revision ID: 0008_symptom_logs
Revises: 0007_doctor_summary_account_event
Create Date: 2026-11-24 18:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0008_symptom_logs'
down_revision: Union[str, None] = '0007_doctor_summary_account_event'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'symptom_logs',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('client_id', sa.UUID(as_uuid=True), nullable=True),
        sa.Column('date', sa.Date(), nullable=False),
        sa.Column('symptom_type', sa.String(length=50), nullable=False),
        sa.Column('custom_label', sa.String(length=100), nullable=True),
        sa.Column('severity', sa.Integer(), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_symptom_logs_user_id', 'symptom_logs', ['user_id'])
    op.create_index('ix_symptom_logs_user_id_date', 'symptom_logs', ['user_id', 'date'])
    op.create_index('ix_symptom_logs_user_id_symptom_type', 'symptom_logs', ['user_id', 'symptom_type'])


def downgrade() -> None:
    op.drop_table('symptom_logs')
