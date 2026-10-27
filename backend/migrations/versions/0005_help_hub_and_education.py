"""0005_help_hub_and_education

Revision ID: 0005_help_hub_and_education
Revises: 0004_study_plans
Create Date: 2026-10-27 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0005_help_hub_and_education'
down_revision: Union[str, None] = '0004_study_plans'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    languages_type = postgresql.ARRAY(sa.String(length=20)).with_variant(sa.JSON(), 'sqlite')
    product_details_type = postgresql.JSONB().with_variant(sa.JSON(), 'sqlite')

    # 1. users.role check constraint
    op.create_check_constraint(
        'ck_users_role',
        'users',
        "role IN ('student', 'moderator', 'resource_admin')",
    )

    # 2. resources table
    op.create_table(
        'resources',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('name', sa.String(length=120), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('description', sa.String(length=600), nullable=False),
        sa.Column('phone', sa.String(length=30), nullable=True),
        sa.Column('email', sa.String(length=255), nullable=True),
        sa.Column('website_url', sa.String(length=500), nullable=True),
        sa.Column('address', sa.String(length=200), nullable=True),
        sa.Column('city', sa.String(length=100), nullable=True),
        sa.Column('hours_text', sa.String(length=200), nullable=True),
        sa.Column('available_24x7', sa.Boolean(), nullable=True),
        sa.Column('languages', languages_type, nullable=False, server_default='[]'),
        sa.Column('cost', sa.String(length=20), server_default='unknown', nullable=False),
        sa.Column('product_details', product_details_type, nullable=True),
        sa.Column('source_url', sa.String(length=500), nullable=True),
        sa.Column('verification_status', sa.String(length=20), server_default='unverified', nullable=False),
        sa.Column('last_verified_at', sa.Date(), nullable=True),
        sa.Column('verified_by', sa.String(length=80), nullable=True),
        sa.Column('is_published', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('is_demo', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint(
            "category IN ('counseling', 'helpline', 'welfare_office', 'period_products', 'ngo', 'health_clinic', 'workshop')",
            name='ck_resources_category',
        ),
        sa.CheckConstraint(
            "cost IN ('free', 'paid', 'unknown')",
            name='ck_resources_cost',
        ),
        sa.CheckConstraint(
            "verification_status IN ('unverified', 'verified', 'outdated')",
            name='ck_resources_verification_status',
        ),
        sa.CheckConstraint(
            "NOT (is_published = true AND is_demo = false) OR (verification_status = 'verified' AND source_url IS NOT NULL AND last_verified_at IS NOT NULL)",
            name='ck_resources_published_verified',
        ),
        sa.CheckConstraint(
            "available_24x7 IS NOT TRUE OR (verification_status = 'verified' AND source_url IS NOT NULL)",
            name='ck_resources_24x7_verified',
        ),
    )
    op.create_index('ix_resources_category_city', 'resources', ['category', 'city'])
    op.create_index('ix_resources_is_published', 'resources', ['is_published'])

    # 3. resource_reports table
    op.create_table(
        'resource_reports',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('resource_id', sa.UUID(as_uuid=True), sa.ForeignKey('resources.id', ondelete='CASCADE'), nullable=False),
        sa.Column('reporter_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('reason', sa.String(length=50), nullable=False),
        sa.Column('note', sa.String(length=300), nullable=True),
        sa.Column('status', sa.String(length=20), server_default='open', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('resolved_note', sa.String(length=300), nullable=True),
        sa.CheckConstraint(
            "reason IN ('outdated', 'out_of_order', 'incorrect', 'closed', 'other')",
            name='ck_resource_reports_reason',
        ),
        sa.CheckConstraint(
            "status IN ('open', 'resolved', 'dismissed')",
            name='ck_resource_reports_status',
        ),
    )
    op.create_index(
        'uq_resource_reports_open',
        'resource_reports',
        ['reporter_id', 'resource_id'],
        unique=True,
        postgresql_where=sa.text("status = 'open'"),
        sqlite_where=sa.text("status = 'open'"),
    )

    # 4. education_resources table
    op.create_table(
        'education_resources',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('slug', sa.String(length=100), nullable=False),
        sa.Column('title', sa.String(length=120), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('language', sa.String(length=10), server_default='en', nullable=False),
        sa.Column('summary', sa.String(length=240), nullable=False),
        sa.Column('body', sa.Text(), nullable=False),
        sa.Column('source_name', sa.String(length=120), nullable=False),
        sa.Column('source_url', sa.String(length=500), nullable=True),
        sa.Column('review_status', sa.String(length=20), server_default='draft', nullable=False),
        sa.Column('reviewed_at', sa.Date(), nullable=True),
        sa.Column('is_published', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint('slug', 'language', name='uq_education_slug_language'),
        sa.CheckConstraint(
            "category IN ('periods_basics', 'hygiene', 'common_symptoms', 'when_to_seek_care', 'emotional_wellbeing', 'supporting_someone')",
            name='ck_education_category',
        ),
        sa.CheckConstraint(
            "language IN ('en', 'hi', 'mr')",
            name='ck_education_language',
        ),
        sa.CheckConstraint(
            "review_status IN ('draft', 'reviewed')",
            name='ck_education_review_status',
        ),
    )
    op.create_index('ix_education_category_language', 'education_resources', ['category', 'language'])
    op.create_index('ix_education_is_published', 'education_resources', ['is_published'])


def downgrade() -> None:
    op.drop_table('education_resources')
    op.drop_table('resource_reports')
    op.drop_table('resources')
    op.drop_constraint('ck_users_role', 'users', type_='check')
