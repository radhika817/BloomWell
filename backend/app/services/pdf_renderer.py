"""In-memory PDF renderer for Doctor-visit summary using ReportLab."""

from datetime import date
import io
from typing import List, Optional
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.schemas.doctor_summary import DoctorSummaryRequest
from app.services.doctor_summary_service import DoctorSummaryData


class NumberedCanvas(canvas.Canvas):
    """Two-pass canvas to dynamically compute and draw total page numbers."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count: int):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#777777"))
        # Header / footer rules
        self.drawString(36, 20, "BloomWell — Confidential personal summary")
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(A4[0] - 36, 20, page_str)
        self.restoreState()


def _build_styles():
    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        "DocTitle",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=18,
        leading=22,
        textColor=colors.HexColor("#1A1A1A"),
        alignment=0,
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
        fontSize=12,
        leading=15,
        textColor=colors.HexColor("#222222"),
        spaceBefore=14,
        spaceAfter=6,
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

    estimate_banner = ParagraphStyle(
        "EstimateBanner",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=10,
        leading=14,
        textColor=colors.HexColor("#1B3A4B"),
        spaceAfter=4,
    )

    estimate_body = ParagraphStyle(
        "EstimateBody",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9,
        leading=13,
        textColor=colors.HexColor("#2B2D42"),
    )

    return {
        "title": title_style,
        "meta": meta_style,
        "section": section_heading,
        "body": body_style,
        "th": table_header,
        "td": table_cell,
        "est_banner": estimate_banner,
        "est_body": estimate_body,
    }


def render_summary(data: DoctorSummaryData, options: DoctorSummaryRequest) -> bytes:
    """
    Pure function that renders a clean, accessible Doctor-visit Summary PDF in memory.
    Guarantees:
      - 100% in-memory rendering via BytesIO (zero disk writes).
      - Strictly NO user identity (name, email, UUID) in document body or PDF metadata.
      - A4 format, plain readable layout, neutral colors, no decorative images.
      - Automatic multi-page flow with dynamic page numbers.
    """
    buffer = io.BytesIO()

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
                end_str = (
                    p.period_end.isoformat() if p.period_end else "End not recorded"
                )
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

            t = Table(table_data, colWidths=[160, 180, 183.27])
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

        story.append(Spacer(1, 10))

    # 3. Symptoms Section (rendered only when options.include.symptoms is True)
    if options.include.symptoms:
        story.append(Paragraph("Logged symptoms", styles["section"]))

        if data.symptoms:
            sym_table_data = [
                [
                    Paragraph("Symptom", styles["th"]),
                    Paragraph("Logs & Severity", styles["th"]),
                    Paragraph("Dates & Notes", styles["th"]),
                ]
            ]

            for s in data.symptoms:
                # Custom label used exactly as saved
                if s.custom_label:
                    label_cell = (
                        f"<b>{s.custom_label}</b><br/>"
                        f"<font color='#555555' size='8'>{s.symptom_type}</font>"
                    )
                else:
                    label_cell = f"<b>{s.symptom_type.replace('_', ' ').capitalize()}</b>"

                # Severity
                if s.min_severity == s.max_severity:
                    sev_str = f"{s.min_severity} / 5"
                else:
                    sev_str = f"{s.min_severity} - {s.max_severity} / 5"

                stat_cell = f"Days: {s.days_logged}<br/>Severity: {sev_str}"

                # Dates & Notes
                dates_str = ", ".join([d.isoformat() for d in s.dates])
                detail_cell = f"Dates: {dates_str}"

                if options.include.symptom_notes and s.notes:
                    for note in s.notes:
                        detail_cell += f"<br/><font color='#333333'><b>User note:</b> {note}</font>"

                sym_table_data.append(
                    [
                        Paragraph(label_cell, styles["td"]),
                        Paragraph(stat_cell, styles["td"]),
                        Paragraph(detail_cell, styles["td"]),
                    ]
                )

            st = Table(sym_table_data, colWidths=[140, 110, 273.27])
            st.setStyle(
                TableStyle(
                    [
                        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#F0F0F0")),
                        ("LINEBELOW", (0, 0), (-1, 0), 1, colors.HexColor("#CCCCCC")),
                        ("LINEBELOW", (0, 1), (-1, -1), 0.5, colors.HexColor("#EAEAEA")),
                        ("ALIGN", (0, 0), (-1, -1), "LEFT"),
                        ("VALIGN", (0, 0), (-1, -1), "TOP"),
                        ("TOPPADDING", (0, 0), (-1, -1), 4),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                        ("LEFTPADDING", (0, 0), (-1, -1), 4),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                    ]
                )
            )
            story.append(st)
        else:
            story.append(
                Paragraph(
                    "No symptoms logged within this date range.", styles["body"]
                )
            )

        story.append(Spacer(1, 10))

    # 4. Estimate Section (rendered only when include.estimate is True AND data.estimate exists)
    if options.include.estimate and data.estimate:
        story.append(Paragraph("Cycle estimate", styles["section"]))

        est = data.estimate
        callout_content = [
            Paragraph(
                "Estimate. This can be wrong. Not medical advice.",
                styles["est_banner"],
            ),
            Paragraph(
                f"Estimated next cycle window: <b>{est.estimated_range_start.isoformat()}</b> to "
                f"<b>{est.estimated_range_end.isoformat()}</b><br/>"
                f"Typical cycle length: {est.typical_cycle_length_days} days<br/>"
                f"<font color='#555555' size='8'>Calculated from your past recorded period starts. "
                f"Actual cycle timing varies naturally.</font>",
                styles["est_body"],
            ),
        ]

        est_box = Table([[callout_content]], colWidths=[523.27])
        est_box.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F4F6F8")),
                    ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#CCD5DE")),
                    ("TOPPADDING", (0, 0), (-1, -1), 8),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                    ("LEFTPADDING", (0, 0), (-1, -1), 10),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 10),
                ]
            )
        )
        story.append(est_box)
        story.append(Spacer(1, 10))

    doc.build(story, canvasmaker=NumberedCanvas)
    return buffer.getvalue()
