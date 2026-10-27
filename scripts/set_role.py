#!/usr/bin/env python3
"""
CLI tool for local administrators to set a user's role by email.
Valid roles: student, moderator, resource_admin.

Security & Privacy Rules:
- Requires an explicit `--yes` flag to apply changes.
- Never prints the raw email or any security tokens in console logs or stdout/stderr.
"""
import argparse
import sys
from pathlib import Path

# Ensure backend/ is in sys.path
repo_root = Path(__file__).resolve().parent.parent
backend_dir = repo_root / "backend"
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from sqlalchemy import select
from app.db.session import SessionLocal
from app.models.user import User

VALID_ROLES = {"student", "moderator", "resource_admin"}


def mask_email(email: str) -> str:
    """Mask email for privacy protection in output."""
    if "@" not in email:
        return "***"
    local, domain = email.split("@", 1)
    if len(local) <= 2:
        masked_local = "*" * len(local)
    else:
        masked_local = f"{local[0]}***{local[-1]}"
    return f"{masked_local}@{domain}"


def set_user_role(email: str, new_role: str, confirm: bool, db_session=None) -> bool:
    """
    Set a user's role in the database.
    Requires confirm=True to persist changes.
    Returns True if role was updated, False otherwise.
    """
    if new_role not in VALID_ROLES:
        print(f"Error: Invalid role. Must be one of: {sorted(VALID_ROLES)}", file=sys.stderr)
        return False

    if not confirm:
        print(
            "Error: Role modification requires explicit confirmation flag '--yes'. Aborting without changes.",
            file=sys.stderr,
        )
        return False

    session = db_session or SessionLocal()
    close_session = db_session is None

    try:
        stmt = select(User).where(User.email == email.strip().lower())
        user = session.scalars(stmt).first()

        if not user:
            print("Error: Account matching specified criteria was not found.", file=sys.stderr)
            return False

        old_role = user.role
        user.role = new_role
        session.commit()

        # Print confirmation using masked email and user ID only
        masked = mask_email(email)
        print(f"Role updated successfully for user {user.id} ({masked}): {old_role} -> {new_role}")
        return True
    finally:
        if close_session:
            session.close()


def main():
    parser = argparse.ArgumentParser(
        description="Safely update a user's role in BloomWell (student, moderator, resource_admin)."
    )
    parser.add_argument(
        "--email",
        required=True,
        help="Email address of the target user",
    )
    parser.add_argument(
        "--role",
        required=True,
        choices=sorted(VALID_ROLES),
        help="Target role (student, moderator, resource_admin)",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        default=False,
        help="Explicit confirmation required to apply changes",
    )

    args = parser.parse_args()

    success = set_user_role(
        email=args.email,
        new_role=args.role,
        confirm=args.yes,
    )
    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
