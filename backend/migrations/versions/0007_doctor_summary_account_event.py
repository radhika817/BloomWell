"""0007_doctor_summary_account_event

Revision ID: 0007_doctor_summary_account_event
Revises: 0006_account_events
Create Date: 2026-11-24 18:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '0007_doctor_summary_account_event'
down_revision: Union[str, None] = '0006_account_events'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add doctor_summary_generated to account_event_type enum in PostgreSQL
    bind = op.get_bind()
    if bind.dialect.name == 'postgresql':
        op.execute("ALTER TYPE account_event_type ADD VALUE IF NOT EXISTS 'doctor_summary_generated'")


def downgrade() -> None:
    # PostgreSQL does not natively support removing a value from an enum type without recreating it
    pass
