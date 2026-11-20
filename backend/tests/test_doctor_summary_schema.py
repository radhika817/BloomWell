"""Tests for Doctor-visit Summary request schema and validation rules."""

from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo
import pytest
from pydantic import ValidationError

from app.core.config import settings
from app.schemas.doctor_summary import (
    DoctorSummaryInclude,
    DoctorSummaryRequest,
    UnsupportedLanguageError,
)


def test_doctor_summary_schema_valid_defaults():
    """Verify default inclusion flags and valid schema instantiation."""
    today = date.today()
    req = DoctorSummaryRequest(
        from_date=today - timedelta(days=30),
        to_date=today,
    )
    assert req.from_date == today - timedelta(days=30)
    assert req.to_date == today
    assert req.language == "en"
    assert req.include.periods is True
    assert req.include.symptoms is True
    assert req.include.symptom_notes is False
    assert req.include.estimate is False
    assert req.include.questions is True


def test_doctor_summary_schema_from_date_after_to_date():
    """Verify from_date cannot be strictly after to_date."""
    today = date.today()
    with pytest.raises(ValidationError) as exc_info:
        DoctorSummaryRequest(
            from_date=today,
            to_date=today - timedelta(days=1),
        )
    assert "from_date cannot be after to_date" in str(exc_info.value)


def test_doctor_summary_schema_same_date_allowed():
    """Verify a 1-day summary (from_date == to_date) is valid."""
    today = date.today()
    req = DoctorSummaryRequest(
        from_date=today,
        to_date=today,
    )
    assert req.from_date == req.to_date


def test_doctor_summary_schema_max_days_limit():
    """Verify range cannot exceed DOCTOR_SUMMARY_MAX_DAYS (366 days)."""
    base_date = date(2025, 1, 1)
    # Exactly 366 days diff is allowed
    req_valid = DoctorSummaryRequest(
        from_date=base_date,
        to_date=base_date + timedelta(days=settings.DOCTOR_SUMMARY_MAX_DAYS),
    )
    assert (req_valid.to_date - req_valid.from_date).days == settings.DOCTOR_SUMMARY_MAX_DAYS

    # 367 days diff is rejected
    with pytest.raises(ValidationError) as exc_info:
        DoctorSummaryRequest(
            from_date=base_date,
            to_date=base_date + timedelta(days=settings.DOCTOR_SUMMARY_MAX_DAYS + 1),
        )
    assert f"exceeds maximum allowed limit of {settings.DOCTOR_SUMMARY_MAX_DAYS} days" in str(
        exc_info.value
    )


def test_doctor_summary_schema_to_date_future_limit_utc():
    """Verify to_date cannot be more than 1 day in the future in UTC."""
    today_utc = datetime.now(ZoneInfo("UTC")).date()

    # today and today + 1 day are valid
    req_today = DoctorSummaryRequest(
        from_date=today_utc - timedelta(days=7),
        to_date=today_utc,
    )
    assert req_today.to_date == today_utc

    req_tomorrow = DoctorSummaryRequest(
        from_date=today_utc - timedelta(days=7),
        to_date=today_utc + timedelta(days=1),
    )
    assert req_tomorrow.to_date == today_utc + timedelta(days=1)

    # today + 2 days is rejected
    with pytest.raises(ValidationError) as exc_info:
        DoctorSummaryRequest(
            from_date=today_utc - timedelta(days=7),
            to_date=today_utc + timedelta(days=2),
        )
    assert "cannot be more than 1 day in the future" in str(exc_info.value)


def test_doctor_summary_schema_to_date_future_limit_with_user_timezone():
    """Verify future date validation correctly accounts for user's timezone."""
    # Test with a timezone where tomorrow's date might differ from UTC
    tz_tokyo = ZoneInfo("Asia/Tokyo")
    today_tokyo = datetime.now(tz_tokyo).date()

    # Validate with context
    req = DoctorSummaryRequest.model_validate(
        {
            "from_date": str(today_tokyo - timedelta(days=10)),
            "to_date": str(today_tokyo + timedelta(days=1)),
        },
        context={"timezone": "Asia/Tokyo"},
    )
    assert req.to_date == today_tokyo + timedelta(days=1)

    # 2 days in the future relative to Tokyo is rejected
    with pytest.raises(ValidationError) as exc_info:
        DoctorSummaryRequest.model_validate(
            {
                "from_date": str(today_tokyo - timedelta(days=10)),
                "to_date": str(today_tokyo + timedelta(days=2)),
            },
            context={"timezone": "Asia/Tokyo"},
        )
    assert "cannot be more than 1 day in the future" in str(exc_info.value)
    assert "Asia/Tokyo" in str(exc_info.value)


def test_doctor_summary_schema_at_least_one_category():
    """Verify that at least one of periods or symptoms must be true."""
    today = date.today()

    # periods=True, symptoms=False -> Valid
    req1 = DoctorSummaryRequest(
        from_date=today - timedelta(days=7),
        to_date=today,
        include=DoctorSummaryInclude(periods=True, symptoms=False),
    )
    assert req1.include.periods is True
    assert req1.include.symptoms is False

    # periods=False, symptoms=True -> Valid
    req2 = DoctorSummaryRequest(
        from_date=today - timedelta(days=7),
        to_date=today,
        include=DoctorSummaryInclude(periods=False, symptoms=True),
    )
    assert req2.include.periods is False
    assert req2.include.symptoms is True

    # periods=False, symptoms=False -> Rejected
    with pytest.raises(ValidationError) as exc_info:
        DoctorSummaryInclude(periods=False, symptoms=False)
    assert "At least one of 'periods' or 'symptoms' must be included" in str(
        exc_info.value
    )


def test_doctor_summary_schema_unsupported_language():
    """Verify non-'en' language raises UnsupportedLanguageError."""
    today = date.today()
    for lang in ["es", "fr", "hi", "mr", "de"]:
        with pytest.raises(ValidationError) as exc_info:
            DoctorSummaryRequest(
                from_date=today - timedelta(days=7),
                to_date=today,
                language=lang,
            )
        assert "unsupported_language" in str(exc_info.value).lower() or "only english" in str(
            exc_info.value
        ).lower()


def test_doctor_summary_schema_forbids_unknown_root_fields():
    """Verify extra root fields are forbidden (especially sensitive fields like journal/mood)."""
    today = str(date.today())
    forbidden_payloads = [
        {"from_date": today, "to_date": today, "journal": "secret entry"},
        {"from_date": today, "to_date": today, "journal_text": "text"},
        {"from_date": today, "to_date": today, "mood": 5},
        {"from_date": today, "to_date": today, "energy": 4},
        {"from_date": today, "to_date": today, "stress": 2},
        {"from_date": today, "to_date": today, "sleep": 3},
        {"from_date": today, "to_date": today, "unexpected_attr": "value"},
    ]
    for payload in forbidden_payloads:
        with pytest.raises(ValidationError) as exc_info:
            DoctorSummaryRequest.model_validate(payload)
        assert "extra_forbidden" in str(exc_info.value)


def test_doctor_summary_schema_forbids_unknown_include_fields():
    """Verify extra include fields are forbidden (no journal, mood, energy, sleep options)."""
    today = str(date.today())
    forbidden_includes = [
        {"journal": True},
        {"journal_text": True},
        {"mood": True},
        {"mood_score": True},
        {"energy": True},
        {"stress": True},
        {"sleep": True},
        {"arbitrary_field": True},
    ]
    for inc in forbidden_includes:
        with pytest.raises(ValidationError) as exc_info:
            DoctorSummaryRequest.model_validate(
                {"from_date": today, "to_date": today, "include": inc}
            )
        assert "extra_forbidden" in str(exc_info.value)
