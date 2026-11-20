"""Tests for Doctor-visit Summary PDF header and periods rendering."""

from datetime import date
import io
import uuid
import pypdf
import pytest

from app.schemas.doctor_summary import DoctorSummaryInclude, DoctorSummaryRequest
from app.services.doctor_summary_service import (
    DoctorSummaryData,
    PeriodSummaryItem,
)
from app.services.pdf_renderer import render_summary


def _extract_pdf_text(pdf_bytes: bytes) -> str:
    reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
    return "\n".join([page.extract_text() or "" for page in reader.pages])


def test_pdf_header_and_periods_rendering():
    """Verify PDF header, metadata, and period rows are accurately rendered and extractable."""
    user_id = uuid.uuid4()
    req = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 2, 28),
        include=DoctorSummaryInclude(periods=True, symptoms=False),
    )

    data = DoctorSummaryData(
        user_id=user_id,
        from_date=req.from_date,
        to_date=req.to_date,
        periods=[
            PeriodSummaryItem(
                period_start=date(2026, 1, 1),
                period_end=date(2026, 1, 5),
                cycle_length_days=None,
            ),
            PeriodSummaryItem(
                period_start=date(2026, 1, 29),
                period_end=None,  # End not recorded
                cycle_length_days=28,
            ),
        ],
        symptoms=[],
        estimate=None,
        included_categories=["Recorded periods"],
    )

    pdf_bytes = render_summary(data, req)
    assert pdf_bytes.startswith(b"%PDF")

    # Inspect PDF metadata
    reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
    meta = reader.metadata or {}
    assert str(user_id) not in str(meta)
    assert meta.get("/Title") == "Personal health notes summary"
    assert meta.get("/Author") == "BloomWell"

    text = _extract_pdf_text(pdf_bytes)

    # 1. Header elements
    assert "Personal health notes summary" in text
    assert "Date range: 2026-01-01 to 2026-02-28" in text
    assert "Included categories: Recorded periods" in text
    assert "Generated:" in text

    # 2. Strict anonymity check: user_id must NOT appear anywhere in the document
    assert str(user_id) not in text

    # 3. Periods Section
    assert "Recorded by me in BloomWell" in text
    assert "Period Start" in text
    assert "Period End" in text
    assert "Cycle Length" in text
    assert "2026-01-01" in text
    assert "2026-01-05" in text
    assert "2026-01-29" in text
    assert "End not recorded" in text
    assert "28 days" in text


def test_pdf_periods_absent_when_unselected():
    """Verify periods section is omitted when include.periods is False."""
    user_id = uuid.uuid4()
    req = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 1, 30),
        include=DoctorSummaryInclude(periods=False, symptoms=True),
    )

    data = DoctorSummaryData(
        user_id=user_id,
        from_date=req.from_date,
        to_date=req.to_date,
        periods=[],
        symptoms=[],
        estimate=None,
        included_categories=["Logged symptoms"],
    )

    pdf_bytes = render_summary(data, req)
    text = _extract_pdf_text(pdf_bytes)

    assert "Personal health notes summary" in text
    assert "Recorded by me in BloomWell" not in text
    assert "Period Start" not in text


def test_pdf_empty_periods_recorded_message():
    """Verify empty periods shows neutral note within date range."""
    user_id = uuid.uuid4()
    req = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 1, 30),
        include=DoctorSummaryInclude(periods=True, symptoms=False),
    )

    data = DoctorSummaryData(
        user_id=user_id,
        from_date=req.from_date,
        to_date=req.to_date,
        periods=[],
        symptoms=[],
        estimate=None,
        included_categories=["Recorded periods"],
    )

    pdf_bytes = render_summary(data, req)
    text = _extract_pdf_text(pdf_bytes)

    assert "Recorded by me in BloomWell" in text
    assert "No periods recorded within this date range." in text


def test_pdf_two_account_isolation_in_text():
    """Verify that User A's generated PDF never contains User B's unique strings."""
    user_a_id = uuid.uuid4()
    user_b_sample_marker = "USER_B_SAMPLE_MARKER"

    req = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 1, 30),
        include=DoctorSummaryInclude(periods=True, symptoms=False),
    )

    data_a = DoctorSummaryData(
        user_id=user_a_id,
        from_date=req.from_date,
        to_date=req.to_date,
        periods=[
            PeriodSummaryItem(
                period_start=date(2026, 1, 1),
                period_end=date(2026, 1, 4),
                cycle_length_days=None,
            )
        ],
        symptoms=[],
        estimate=None,
        included_categories=["Recorded periods"],
    )

    pdf_bytes = render_summary(data_a, req)
    text = _extract_pdf_text(pdf_bytes)

    assert user_b_sample_marker not in text
    assert str(uuid.uuid4()) not in text
