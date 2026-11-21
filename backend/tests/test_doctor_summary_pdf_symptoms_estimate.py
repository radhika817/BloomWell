"""Tests for Doctor-visit Summary PDF symptoms, estimate, and multi-page flow."""

from datetime import date, timedelta
import io
import uuid
import pypdf
import pytest

from app.schemas.doctor_summary import DoctorSummaryInclude, DoctorSummaryRequest
from app.services.doctor_summary_service import (
    DoctorSummaryData,
    EstimateSummaryItem,
    PeriodSummaryItem,
    SymptomSummaryGroup,
)
from app.services.pdf_renderer import render_summary


def _extract_pages_text(pdf_bytes: bytes) -> list[str]:
    reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
    return [page.extract_text() or "" for page in reader.pages]


def test_pdf_symptoms_rendering_with_custom_labels_and_notes():
    """Verify symptom groupings, exact custom labels, and user notes labeled correctly."""
    user_id = uuid.uuid4()
    req = DoctorSummaryRequest(
        from_date=date(2026, 2, 1),
        to_date=date(2026, 2, 28),
        include=DoctorSummaryInclude(periods=False, symptoms=True, symptom_notes=True),
    )

    data = DoctorSummaryData(
        user_id=user_id,
        from_date=req.from_date,
        to_date=req.to_date,
        periods=[],
        symptoms=[
            SymptomSummaryGroup(
                symptom_type="cramps",
                custom_label="Lower Pelvic Pain",
                days_logged=3,
                min_severity=2,
                max_severity=4,
                dates=[date(2026, 2, 2), date(2026, 2, 3), date(2026, 2, 4)],
                notes=["Felt worse after evening walk", "Took warm bath"],
            ),
            SymptomSummaryGroup(
                symptom_type="headache",
                custom_label=None,
                days_logged=1,
                min_severity=3,
                max_severity=3,
                dates=[date(2026, 2, 10)],
                notes=[],
            ),
        ],
        estimate=None,
        included_categories=["Logged symptoms", "Symptom notes"],
    )

    pdf_bytes = render_summary(data, req)
    full_text = "\n".join(_extract_pages_text(pdf_bytes))

    assert "Logged symptoms" in full_text
    assert "Lower Pelvic Pain" in full_text
    assert "Days: 3" in full_text
    assert "Severity: 2 - 4 / 5" in full_text
    assert "2026-02-02, 2026-02-03, 2026-02-04" in full_text

    # Verify user note formatting
    assert "User note: Felt worse after evening walk" in full_text
    assert "User note: Took warm bath" in full_text

    # Default symptom type without custom label
    assert "Headache" in full_text
    assert "Severity: 3 / 5" in full_text


def test_pdf_symptoms_notes_excluded_when_toggle_false():
    """Verify user notes are completely omitted when symptom_notes is False."""
    user_id = uuid.uuid4()
    req = DoctorSummaryRequest(
        from_date=date(2026, 2, 1),
        to_date=date(2026, 2, 28),
        include=DoctorSummaryInclude(periods=False, symptoms=True, symptom_notes=False),
    )

    data = DoctorSummaryData(
        user_id=user_id,
        from_date=req.from_date,
        to_date=req.to_date,
        periods=[],
        symptoms=[
            SymptomSummaryGroup(
                symptom_type="bloating",
                custom_label="Morning Bloat",
                days_logged=1,
                min_severity=2,
                max_severity=2,
                dates=[date(2026, 2, 5)],
                notes=["This note should not be in PDF"],
            )
        ],
        estimate=None,
        included_categories=["Logged symptoms"],
    )

    pdf_bytes = render_summary(data, req)
    full_text = "\n".join(_extract_pages_text(pdf_bytes))

    assert "Morning Bloat" in full_text
    assert "User note:" not in full_text
    assert "This note should not be in PDF" not in full_text


def test_pdf_estimate_section_wording_and_range():
    """Verify estimate is styled with exact uncertainty wording and a date range, never a single date."""
    user_id = uuid.uuid4()
    req = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 3, 31),
        include=DoctorSummaryInclude(periods=True, symptoms=False, estimate=True),
    )

    data = DoctorSummaryData(
        user_id=user_id,
        from_date=req.from_date,
        to_date=req.to_date,
        periods=[],
        symptoms=[],
        estimate=EstimateSummaryItem(
            status="estimate",
            typical_cycle_length_days=29,
            estimated_range_start=date(2026, 4, 18),
            estimated_range_end=date(2026, 4, 24),
            explanation=None,
        ),
        included_categories=["Recorded periods", "Cycle estimate"],
    )

    pdf_bytes = render_summary(data, req)
    full_text = "\n".join(_extract_pages_text(pdf_bytes))

    # Mandatory clinical safeguards wording
    assert "Cycle estimate" in full_text
    assert "Estimate. This can be wrong. Not medical advice." in full_text
    assert "2026-04-18" in full_text
    assert "2026-04-24" in full_text
    assert "Typical cycle length: 29 days" in full_text


def test_pdf_estimate_section_absent_when_unselected_or_unavailable():
    """Verify estimate section is omitted when not included or when data.estimate is None."""
    user_id = uuid.uuid4()

    # 1. include.estimate is False
    req1 = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 3, 31),
        include=DoctorSummaryInclude(periods=True, symptoms=False, estimate=False),
    )
    data1 = DoctorSummaryData(
        user_id=user_id,
        from_date=req1.from_date,
        to_date=req1.to_date,
        periods=[],
        symptoms=[],
        estimate=None,
        included_categories=["Recorded periods"],
    )
    pdf_bytes1 = render_summary(data1, req1)
    assert "Estimate. This can be wrong" not in "\n".join(_extract_pages_text(pdf_bytes1))

    # 2. include.estimate is True but data.estimate is None (e.g. not enough data)
    req2 = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 3, 31),
        include=DoctorSummaryInclude(periods=True, symptoms=False, estimate=True),
    )
    data2 = DoctorSummaryData(
        user_id=user_id,
        from_date=req2.from_date,
        to_date=req2.to_date,
        periods=[],
        symptoms=[],
        estimate=None,
        included_categories=["Recorded periods"],
    )
    pdf_bytes2 = render_summary(data2, req2)
    assert "Estimate. This can be wrong" not in "\n".join(_extract_pages_text(pdf_bytes2))


def test_pdf_multi_page_flow_and_page_numbering():
    """Verify multi-page documents render total page numbers correctly on every page."""
    user_id = uuid.uuid4()
    req = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 3, 31),
        include=DoctorSummaryInclude(periods=True, symptoms=True, symptom_notes=True, estimate=True),
    )

    # Generate 25 distinct symptom groups to guarantee spilling onto page 2
    many_symptoms = [
        SymptomSummaryGroup(
            symptom_type=f"symptom_type_{i}",
            custom_label=f"Custom Description For Test Row {i}",
            days_logged=i % 5 + 1,
            min_severity=1,
            max_severity=4,
            dates=[date(2026, 1, 1) + timedelta(days=j) for j in range(i % 5 + 1)],
            notes=[f"User note details for symptom entry {i} spanning detailed text."],
        )
        for i in range(25)
    ]

    data = DoctorSummaryData(
        user_id=user_id,
        from_date=req.from_date,
        to_date=req.to_date,
        periods=[
            PeriodSummaryItem(
                period_start=date(2026, 1, 1),
                period_end=date(2026, 1, 5),
                cycle_length_days=None,
            )
        ],
        symptoms=many_symptoms,
        estimate=EstimateSummaryItem(
            status="estimate",
            typical_cycle_length_days=28,
            estimated_range_start=date(2026, 4, 1),
            estimated_range_end=date(2026, 4, 6),
            explanation=None,
        ),
        included_categories=["Recorded periods", "Logged symptoms", "Symptom notes", "Cycle estimate"],
    )

    pdf_bytes = render_summary(data, req)
    pages_text = _extract_pages_text(pdf_bytes)

    # Must span at least 2 pages
    assert len(pages_text) >= 2
    total_pages = len(pages_text)

    # Check page numbering on first and last page
    assert f"Page 1 of {total_pages}" in pages_text[0]
    assert f"Page {total_pages} of {total_pages}" in pages_text[-1]
    assert "BloomWell — Confidential personal summary" in pages_text[0]
