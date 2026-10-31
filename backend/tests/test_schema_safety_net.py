import pytest
import sqlalchemy as sa
from sqlalchemy.schema import Table

from app.db.base import Base
import app.models  # Ensure all SQLAlchemy models are imported and registered
from app.services.deletion_service import deletion_registry
from app.services.export_service import EXPORT_EXCLUDED, export_registry


def _get_live_user_owned_tables() -> set[str]:
    """
    Inspect live SQLAlchemy metadata for all tables that have a foreign key to
    users.id or have a user_id column (excluding users itself and account_events,
    which cascade automatically with the account).
    """
    user_owned = set()
    for table_name, table in Base.metadata.tables.items():
        if table_name in ("users", "account_events"):
            continue

        has_fk_to_users = any(
            fk.column.table.name == "users"
            for fk in table.foreign_keys
        )
        has_user_col = "user_id" in table.columns

        if has_fk_to_users or has_user_col:
            user_owned.add(table_name)

    return user_owned


def test_schema_introspection_safety_net():
    """
    CRITICAL SCHEMA-INTROSPECTION SAFETY NET:
    Every table in the database that has a foreign key to users.id or a user_id column
    must be:
      (a) explicitly handled by deletion_registry
      (b) covered by export_registry OR explicitly listed in EXPORT_EXCLUDED with a written reason.

    If this test fails, a newly added user-owned table is missing from deletion or export!
    Update app/services/deletion_service.py and app/services/export_service.py.
    """
    user_owned_tables = _get_live_user_owned_tables()
    assert len(user_owned_tables) > 0, "Safety net check error: no user-owned tables discovered."

    deletion_tables = deletion_registry.get_registered_tables()
    export_tables = export_registry.get_registered_tables()
    excluded_tables = set(EXPORT_EXCLUDED.keys())

    missing_from_deletion = user_owned_tables - deletion_tables
    assert not missing_from_deletion, (
        f"SAFETY NET FAILURE: The following user-owned tables are NOT handled by deletion_registry: "
        f"{missing_from_deletion}. You must add an explicit table deleter to app/services/deletion_service.py."
    )

    missing_from_export = user_owned_tables - (export_tables | excluded_tables)
    assert not missing_from_export, (
        f"SAFETY NET FAILURE: The following user-owned tables are NOT covered by export_registry "
        f"or listed in EXPORT_EXCLUDED: {missing_from_export}. "
        f"You must register an exporter in app/services/export_service.py or add to EXPORT_EXCLUDED with justification."
    )


def test_schema_introspection_safety_net_fails_on_unhandled_table():
    """
    Demonstrate that the introspection safety net genuinely catches and fails
    when a new user-owned table is added to metadata without registry entries.
    """
    dummy_table_name = "test_dummy_user_records"
    dummy_table = Table(
        dummy_table_name,
        Base.metadata,
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.UUID(as_uuid=True), sa.ForeignKey("users.id")),
    )

    try:
        user_owned_tables = _get_live_user_owned_tables()
        assert dummy_table_name in user_owned_tables

        deletion_tables = deletion_registry.get_registered_tables()
        missing_deletion = user_owned_tables - deletion_tables
        assert dummy_table_name in missing_deletion, "Safety net must identify dummy table missing from deletion"

        export_tables = export_registry.get_registered_tables()
        missing_export = user_owned_tables - (export_tables | set(EXPORT_EXCLUDED.keys()))
        assert dummy_table_name in missing_export, "Safety net must identify dummy table missing from export"
    finally:
        # Clean up metadata so other tests are unaffected
        Base.metadata.remove(dummy_table)
