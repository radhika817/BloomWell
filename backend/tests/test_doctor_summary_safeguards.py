"""Tests for Doctor-visit Summary questions, closing disclaimer, and clinical wording safeguards."""

from datetime import date
import io
import uuid
import pypdf
import pytest

from app.core.doctor_summary_constants import (
    DOCTOR_SUMMARY_DISCLAIMER,
    DOCTOR_SUMMARY_QUESTIONS,
    FORBIDDEN_WORDS,
)
from app.schemas.doctor_summary import DoctorSummaryInclude, DoctorSummaryRequest
from app.services.doctor_summary_service import (
    DoctorSummaryData,
    EstimateSummaryItem,
    PeriodSummaryItem,
    SymptomSummaryGroup,
)
from app.services.pdf_renderer import render_summary


def _extract_pdf_text(pdf_bytes: bytes) -> str:
    reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
    return "\n".join([page.extract_text() or "" for page in reader.pages])


def _normalize_whitespace(text: str) -> str:
    return " ".join(text.split())


def test_constants_free_of_forbidden_words():
    """Verify constant questions and disclaimer contain none of the diagnostic/medical claim words."""
    assert len(DOCTOR_SUMMARY_QUESTIONS) >= 6
    assert DOCTOR_SUMMARY_DISCLAIMER.strip() != ""

    all_constant_text = "\n".join(DOCTOR_SUMMARY_QUESTIONS) + "\n" + DOCTOR_SUMMARY_DISCLAIMER
    lower_text = all_constant_text.lower()

    for forbidden in FORBIDDEN_WORDS:
        assert forbidden.lower() not in lower_text, (
            f"Wording safeguard violation: forbidden word '{forbidden}' found in constants module."
        )


def test_full_pdf_free_of_forbidden_words():
    """Verify that a fully populated PDF containing all sections contains none of the forbidden words."""
    user_id = uuid.uuid4()
    req = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 3, 31),
        include=DoctorSummaryInclude(
            periods=True,
            symptoms=True,
            symptom_notes=True,
            estimate=True,
            questions=True,
        ),
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
                period_end=date(2026, 2, 3),
                cycle_length_days=28,
            ),
        ],
        symptoms=[
            SymptomSummaryGroup(
                symptom_type="cramps",
                custom_label="Lower Back Tightness",
                days_logged=2,
                min_severity=2,
                max_severity=3,
                dates=[date(2026, 1, 2), date(2026, 1, 3)],
                notes=["Used heat wrap in afternoon"],
            )
        ],
        estimate=EstimateSummaryItem(
            status="estimate",
            typical_cycle_length_days=28,
            estimated_range_start=date(2026, 4, 20),
            estimated_range_end=date(2026, 4, 26),
            explanation=None,
        ),
        included_categories=[
            "Recorded periods",
            "Logged symptoms",
            "Symptom notes",
            "Cycle estimate",
            "Suggested questions",
        ],
    )

    pdf_bytes = render_summary(data, req)
    full_text = _extract_pdf_text(pdf_bytes)
    lower_pdf_text = full_text.lower()

    for forbidden in FORBIDDEN_WORDS:
        assert forbidden.lower() not in lower_pdf_text, (
            f"Clinical integrity violation: forbidden term '{forbidden}' found in generated PDF text."
        )


def test_disclaimer_always_present_in_pdf():
    """Verify the mandatory closing disclaimer is always rendered regardless of category choices."""
    user_id = uuid.uuid4()

    # Minimal request with only periods
    req1 = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 1, 30),
        include=DoctorSummaryInclude(periods=True, symptoms=False, questions=False),
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
    pdf1 = render_summary(data1, req1)
    text1 = _normalize_whitespace(_extract_pdf_text(pdf1))
    assert _normalize_whitespace(DOCTOR_SUMMARY_DISCLAIMER) in text1

    # Minimal request with only symptoms and questions False
    req2 = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 1, 30),
        include=DoctorSummaryInclude(periods=False, symptoms=True, questions=False),
    )
    data2 = DoctorSummaryData(
        user_id=user_id,
        from_date=req2.from_date,
        to_date=req2.to_date,
        periods=[],
        symptoms=[],
        estimate=None,
        included_categories=["Logged symptoms"],
    )
    pdf2 = render_summary(data2, req2)
    text2 = _normalize_whitespace(_extract_pdf_text(pdf2))
    assert _normalize_whitespace(DOCTOR_SUMMARY_DISCLAIMER) in text2


def test_questions_section_toggle():
    """Verify suggested questions appear only when include.questions is True."""
    user_id = uuid.uuid4()

    # 1. Questions included
    req_yes = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 1, 30),
        include=DoctorSummaryInclude(periods=True, symptoms=False, questions=True),
    )
    data_yes = DoctorSummaryData(
        user_id=user_id,
        from_date=req_yes.from_date,
        to_date=req_yes.to_date,
        periods=[],
        symptoms=[],
        estimate=None,
        included_categories=["Recorded periods", "Suggested questions"],
    )
    text_yes = _extract_pdf_text(render_summary(data_yes, req_yes))
    assert "Questions you may want to ask" in text_yes
    for q in DOCTOR_SUMMARY_QUESTIONS:
        assert q in text_yes

    # 2. Questions excluded
    req_no = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 1, 30),
        include=DoctorSummaryInclude(periods=True, symptoms=False, questions=False),
    )
    data_no = DoctorSummaryData(
        user_id=user_id,
        from_date=req_no.from_date,
        to_date=req_no.to_date,
        periods=[],
        symptoms=[],
        estimate=None,
        included_categories=["Recorded periods"],
    )
    text_no = _extract_pdf_text(render_summary(data_no, req_no))
    assert "Questions you may want to ask" not in text_no
