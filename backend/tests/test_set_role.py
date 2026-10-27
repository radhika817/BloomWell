import io
import sys
from pathlib import Path
import pytest
from sqlalchemy.orm import Session

repo_root = Path(__file__).resolve().parent.parent.parent
if str(repo_root) not in sys.path:
    sys.path.insert(0, str(repo_root))

from scripts.set_role import set_user_role, mask_email
from app.models.user import User


def test_mask_email():
    assert mask_email("student@campus.edu") == "s***t@campus.edu"
    assert mask_email("a@b.com") == "*@b.com"


def test_set_role_requires_yes_flag(db_session: Session, capsys):
    user = User(
        email="test.student@campus.edu",
        password_hash="hashed_pw",
        role="student",
    )
    db_session.add(user)
    db_session.commit()

    # 1. Missing confirm (confirm=False) must abort and leave role unchanged
    res = set_user_role(
        email="test.student@campus.edu",
        new_role="resource_admin",
        confirm=False,
        db_session=db_session,
    )
    assert res is False
    db_session.refresh(user)
    assert user.role == "student"

    captured = capsys.readouterr()
    assert "Aborting without changes" in captured.err
    # Raw email must never be printed
    assert "test.student@campus.edu" not in captured.out
    assert "test.student@campus.edu" not in captured.err

    # 2. Invalid role rejected
    res_inv = set_user_role(
        email="test.student@campus.edu",
        new_role="superadmin",
        confirm=True,
        db_session=db_session,
    )
    assert res_inv is False
    db_session.refresh(user)
    assert user.role == "student"

    # 3. With confirm=True, role updates successfully
    res_success = set_user_role(
        email="test.student@campus.edu",
        new_role="resource_admin",
        confirm=True,
        db_session=db_session,
    )
    assert res_success is True
    db_session.refresh(user)
    assert user.role == "resource_admin"

    captured_success = capsys.readouterr()
    assert "Role updated successfully" in captured_success.out
    assert "test.student@campus.edu" not in captured_success.out
    assert "t***t@campus.edu" in captured_success.out
