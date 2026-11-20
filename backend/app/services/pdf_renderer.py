"""In-memory PDF renderer for Doctor-visit summary using ReportLab."""

from datetime import date
import io
from typing import List
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.schemas.doctor_summary import DoctorSummaryRequest
from app.services.doctor_summary_service import DoctorSummaryData


def _build_styles():
    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        "DocTitle",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=18,
        leading=22,
        textColor=colors.HexColor("#1A1A1A"),
        alignment=0,  # Left-aligned
        spaceAfter=8,
    )

    meta_style = ParagraphStyle(
        "DocMeta",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9,
        leading=13,
        textColor=colors.HexColor("#4A4A4A"),
    )

    section_heading = ParagraphStyle(
        "SectionHeading",
        parent=styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=13,
        leading=16,
        textColor=colors.HexColor("#222222"),
        spaceBefore=14,
        spaceAfter=8,
        keepWithNext=True,
    )

    body_style = ParagraphStyle(
        "DocBody",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9,
        leading=13,
        textColor=colors.HexColor("#333333"),
    )

    table_header = ParagraphStyle(
        "TableHeader",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=9,
        leading=11,
        textColor=colors.HexColor("#1A1A1A"),
    )

    table_cell = ParagraphStyle(
        "TableCell",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9,
        leading=12,
        textColor=colors.HexColor("#222222"),
    )

    return {
        "title": title_style,
        "meta": meta_style,
        "section": section_heading,
        "body": body_style,
        "th": table_header,
        "td": table_cell,
    }


def render_summary(data: DoctorSummaryData, options: DoctorSummaryRequest) -> bytes:
    """
    Pure function that renders a clean, accessible Doctor-visit Summary PDF in memory.
    Guarantees:
      - 100% in-memory rendering via BytesIO (zero disk writes).
      - Strictly NO user identity (name, email, UUID) in document body or PDF metadata.
      - A4 format, plain readable layout, neutral colors, no decorative images.
    """
    buffer = io.BytesIO()

    # Document setup with anonymous metadata
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=36,
        title="Personal health notes summary",
        author="BloomWell",
        creator="BloomWell",
        subject="Personal health notes summary",
    )

    styles = _build_styles()
    story = []

    # 1. Document Header
    story.append(Paragraph("Personal health notes summary", styles["title"]))

    gen_date = date.today().isoformat()
    meta_text = (
        f"<b>Date range:</b> {data.from_date.isoformat()} to {data.to_date.isoformat()}<br/>"
        f"<b>Generated:</b> {gen_date}<br/>"
        f"<b>Included categories:</b> {', '.join(data.included_categories)}"
    )
    story.append(Paragraph(meta_text, styles["meta"]))
    story.append(Spacer(1, 10))

    # 2. Periods Section (rendered only when options.include.periods is True)
    if options.include.periods:
        story.append(Paragraph("Recorded by me in BloomWell", styles["section"]))

        if data.periods:
            table_data = [
                [
                    Paragraph("Period Start", styles["th"]),
                    Paragraph("Period End", styles["th"]),
                    Paragraph("Cycle Length", styles["th"]),
                ]
            ]
            for p in data.periods:
                end_str = p.period_end.isoformat() if p.period_end else "End not recorded"
                length_str = (
                    f"{p.cycle_length_days} days"
                    if p.cycle_length_days is not None
                    else "—"
                )
                table_data.append(
                    [
                        Paragraph(p.period_start.isoformat(), styles["td"]),
                        Paragraph(end_str, styles["td"]),
                        Paragraph(length_str, styles["td"]),
                    ]
                )

            # Available page width: 595.27 (A4 width) - 72 (margins) = 523.27
            t = Table(table_data, colWidths=[160, 180, 183])
            t.setStyle(
                TableStyle(
                    [
                        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#F0F0F0")),
                        ("LINEBELOW", (0, 0), (-1, 0), 1, colors.HexColor("#CCCCCC")),
                        ("LINEBELOW", (0, 1), (-1, -1), 0.5, colors.HexColor("#EAEAEA")),
                        ("ALIGN", (0, 0), (-1, -1), "LEFT"),
                        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                        ("TOPPADDING", (0, 0), (-1, -1), 4),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                        ("LEFTPADDING", (0, 0), (-1, -1), 4),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                    ]
                )
            )
            story.append(t)
        else:
            story.append(
                Paragraph(
                    "No periods recorded within this date range.", styles["body"]
                )
            )

        story.append(Spacer(1, 12))

    doc.build(story)
    return buffer.getvalue()
