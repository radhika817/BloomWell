#!/usr/bin/env python3
"""
Seed script for reviewed menstrual education content in BloomWell.
Creates 8 original English articles in plain, supportive, non-clinical language.
Adheres strictly to vocabulary guardrails: no diagnostic claims, no medical treatments,
no dosage advice, and no fertility or pregnancy content.
Every item starts as review_status='draft' with source_name='BloomWell team draft'.
"""
import sys
import uuid
from pathlib import Path

# Ensure backend/ is in sys.path
repo_root = Path(__file__).resolve().parent.parent
backend_dir = repo_root / "backend"
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from sqlalchemy import select
from app.db.session import SessionLocal
from app.models.education import (
    EducationCategory,
    EducationLanguage,
    EducationResource,
    ReviewStatus,
)

EDUCATION_ARTICLES = [
    {
        "slug": "what-is-a-period",
        "title": "Understanding What a Period Is",
        "category": EducationCategory.PERIODS_BASICS.value,
        "language": EducationLanguage.EN.value,
        "summary": "A gentle and simple guide to understanding your monthly menstrual cycle and what happens in the body.",
        "body": (
            "A menstrual period is a natural bodily process that most women experience each month. "
            "During each cycle, the lining of the uterus builds up a soft cushion. When that lining "
            "is not needed, the body naturally releases it through the vagina over a span of several days.\n\n"
            "Bleeding typically lasts between three to seven days, and flow can vary from light to moderate "
            "or heavier on different days. Everyone experiences their cycle in their own unique way, and "
            "paying attention to how you feel helps you listen to your body with patience and care.\n\n"
            "When to talk to a doctor or nurse: If bleeding feels unusually heavy, lasts longer than a week, "
            "or causes you to feel faint or exhausted, consulting a healthcare professional offers personalized guidance."
        ),
        "source_name": "BloomWell team draft",
        "source_url": None,
        "review_status": ReviewStatus.DRAFT.value,
        "is_published": True,
    },
    {
        "slug": "everyday-hygiene-basics",
        "title": "Everyday Menstrual Hygiene Basics",
        "category": EducationCategory.HYGIENE.value,
        "language": EducationLanguage.EN.value,
        "summary": "Practical and comfortable hygiene habits to keep you fresh, comfortable, and confident every day.",
        "body": (
            "Practicing good personal hygiene during your period helps you stay fresh and comfortable throughout your day. "
            "Washing your hands with clean water and mild soap before and after handling any period product is a simple and "
            "essential first step.\n\n"
            "Change disposable pads every four to six hours, or whenever they feel full, to support skin freshness. "
            "If using reusable products such as menstrual cups or cloth pads, follow clean washing and drying practices. "
            "When disposing of pads, wrap them neatly in paper or disposal bags and place them into designated dustbins, "
            "never flushing them down toilets.\n\n"
            "When to talk to a doctor or nurse: If you experience itching, burning sensations, or notice an unfamiliar strong odor, "
            "reaching out to a healthcare provider or campus nurse can help you address any discomfort safely."
        ),
        "source_name": "BloomWell team draft",
        "source_url": None,
        "review_status": ReviewStatus.DRAFT.value,
        "is_published": True,
    },
    {
        "slug": "comfort-and-common-symptoms",
        "title": "Finding Comfort During Common Symptoms",
        "category": EducationCategory.COMMON_SYMPTOMS.value,
        "language": EducationLanguage.EN.value,
        "summary": "Gentle self-care routines, restful habits, and comfort ideas for days when your energy dips.",
        "body": (
            "It is completely normal to notice changes in how your body feels before and during your period. "
            "Many people experience mild lower belly tightness, lower back heaviness, tender spots, or shifts in energy. "
            "These sensations are common responses to the natural rhythm of your cycle.\n\n"
            "Gentle self-care can bring great relief. Applying a warm water bottle to your lower abdomen, sipping warm herbal "
            "tea, taking a warm shower, and gentle stretching or slow walks can help your muscles relax. Prioritizing rest, "
            "staying well-hydrated, and enjoying balanced meals support steady energy throughout student life.\n\n"
            "When to talk to a doctor or nurse: If body aches or cramps are intense enough to prevent you from attending class, "
            "studying, or sleeping comfortably, speaking with a medical professional can help you explore safe supportive options."
        ),
        "source_name": "BloomWell team draft",
        "source_url": None,
        "review_status": ReviewStatus.DRAFT.value,
        "is_published": True,
    },
    {
        "slug": "when-to-seek-professional-care",
        "title": "Knowing When to Seek Professional Assessment",
        "category": EducationCategory.WHEN_TO_SEEK_CARE.value,
        "language": EducationLanguage.EN.value,
        "summary": "A supportive checklist to help you decide when having a conversation with a doctor or nurse is beneficial.",
        "body": (
            "Learning to listen to your body also means recognizing when outside guidance can give you peace of mind. "
            "While cycles vary widely from person to person, seeking medical advice is always a proactive step toward your well-being.\n\n"
            "Consider scheduling a visit with a doctor or campus nurse if your period suddenly stops for multiple months, "
            "if bleeding occurs frequently between expected cycles, or if pain does not ease with rest and warmth. "
            "Healthcare providers are there to listen respectfully and answer your questions without judgment.\n\n"
            "When to talk to a doctor or nurse: Whenever you feel uncertain, overwhelmed by physical symptoms, or simply want "
            "clear answers about your personal health, making an appointment with a clinic provides compassionate assistance."
        ),
        "source_name": "BloomWell team draft",
        "source_url": None,
        "review_status": ReviewStatus.DRAFT.value,
        "is_published": True,
    },
    {
        "slug": "emotional-wellbeing-and-kindness",
        "title": "Emotional Well-Being and Practicing Self-Kindness",
        "category": EducationCategory.EMOTIONAL_WELLBEING.value,
        "language": EducationLanguage.EN.value,
        "summary": "Navigating emotional fluctuations and academic expectations with compassion for yourself.",
        "body": (
            "Emotional shifts often accompany physical changes during different phases of your cycle. You might feel energetic "
            "and social one week, and notice yourself feeling more reflective, quiet, or sensitive the next week. "
            "These variations are natural, valid, and worthy of gentle acceptance.\n\n"
            "Giving yourself permission to adjust your pace is a form of self-kindness. Breaking academic tasks into smaller steps, "
            "scheduling quiet breathing breaks, and writing down thoughts in a private journal can create emotional space. "
            "You do not need to push through exhaustion every single day.\n\n"
            "When to talk to a doctor or nurse: If persistent low mood, deep sadness, or intense anxiety makes everyday activities "
            "feel unbearable, reaching out to a mental health counselor or healthcare provider offers dedicated support."
        ),
        "source_name": "BloomWell team draft",
        "source_url": None,
        "review_status": ReviewStatus.DRAFT.value,
        "is_published": True,
    },
    {
        "slug": "supporting-a-friend",
        "title": "How to Support a Friend During Their Period",
        "category": EducationCategory.SUPPORTING_SOMEONE.value,
        "language": EducationLanguage.EN.value,
        "summary": "Thoughtful ways to show empathy, share practical supplies, and break campus stigma together.",
        "body": (
            "Supporting a friend during their period is about warmth, discretion, and practical kindness. Small everyday gestures "
            "can make a huge difference in helping someone feel safe and supported in college.\n\n"
            "Keep an extra clean pad or product in your bag so you can share if someone is caught off guard. "
            "If a friend feels tired or experiences discomfort during classes, offer to take lecture notes, fetch a warm drink, "
            "or walk with them to the restroom. Simple questions like 'Would you like some quiet time or some company?' show deep care.\n\n"
            "When to talk to a doctor or nurse: If your friend is experiencing severe pain or feels dizzy and unwell, gently suggest "
            "visiting the campus health clinic together and offer to accompany them for moral support."
        ),
        "source_name": "BloomWell team draft",
        "source_url": None,
        "review_status": ReviewStatus.DRAFT.value,
        "is_published": True,
    },
    {
        "slug": "how-parents-and-family-can-support",
        "title": "How Families and Guardians Can Offer Support",
        "category": EducationCategory.SUPPORTING_SOMEONE.value,
        "language": EducationLanguage.EN.value,
        "summary": "Creating an open, supportive, and stigma-free home environment for young people experiencing menstruation.",
        "body": (
            "Family support plays a fundamental role in shaping how young people view their bodies and health. "
            "Open, matter-of-fact conversations free from hesitation or shame help build lifelong confidence.\n\n"
            "Ensure period products, clean water, and private waste disposal are always accessible at home without awkwardness. "
            "Listen with patience when someone mentions fatigue or discomfort, and validate their feelings instead of dismissing them. "
            "Encouraging balance between study and rest models healthy self-care for young students.\n\n"
            "When to talk to a doctor or nurse: If a family member expresses ongoing distress or severe discomfort with their cycle, "
            "helping them arrange a visit with a friendly healthcare professional provides reliable guidance."
        ),
        "source_name": "BloomWell team draft",
        "source_url": None,
        "review_status": ReviewStatus.DRAFT.value,
        "is_published": True,
    },
    {
        "slug": "talking-comfortably-with-a-health-worker",
        "title": "Talking Comfortably With a Healthcare Professional",
        "category": EducationCategory.WHEN_TO_SEEK_CARE.value,
        "language": EducationLanguage.EN.value,
        "summary": "Simple preparation tips for discussing cycle questions and personal comfort with a doctor or nurse.",
        "body": (
            "Visiting a health professional to talk about your period is a completely standard, confidential consultation. "
            "Doctors and nurses speak about cycles every day, and their role is to listen and assist you.\n\n"
            "Before your appointment, jot down a few notes on your phone: dates when your last couple of periods began, "
            "the general intensity of your flow, and any specific feelings or questions you have. Having notes handy can help "
            "you feel relaxed and confident during the conversation. You can also ask a trusted friend to wait outside for company.\n\n"
            "When to talk to a doctor or nurse: Reaching out whenever you have questions about your body is always appropriate. "
            "Healthcare workers are there to guide you and support your personal wellness journey."
        ),
        "source_name": "BloomWell team draft",
        "source_url": None,
        "review_status": ReviewStatus.DRAFT.value,
        "is_published": True,
    },
]


def seed_education(db_session=None) -> tuple[int, int]:
    """
    Upsert the 8 educational articles idempotently.
    Returns (created_count, updated_count).
    """
    session = db_session or SessionLocal()
    close_session = db_session is None

    created = 0
    updated = 0

    try:
        for data in EDUCATION_ARTICLES:
            stmt = select(EducationResource).where(
                EducationResource.slug == data["slug"],
                EducationResource.language == data["language"],
            )
            existing = session.scalars(stmt).first()

            if existing:
                existing.title = data["title"]
                existing.category = data["category"]
                existing.summary = data["summary"]
                existing.body = data["body"]
                existing.source_name = data["source_name"]
                existing.source_url = data["source_url"]
                existing.review_status = data["review_status"]
                existing.is_published = data["is_published"]
                updated += 1
            else:
                item = EducationResource(
                    id=uuid.uuid4(),
                    slug=data["slug"],
                    title=data["title"],
                    category=data["category"],
                    language=data["language"],
                    summary=data["summary"],
                    body=data["body"],
                    source_name=data["source_name"],
                    source_url=data["source_url"],
                    review_status=data["review_status"],
                    is_published=data["is_published"],
                )
                session.add(item)
                created += 1

        session.commit()
    finally:
        if close_session:
            session.close()

    return created, updated


def main():
    print("Seeding BloomWell educational articles...")
    created, updated = seed_education()
    print(f"Education seeding complete: {created} created, {updated} updated.")


if __name__ == "__main__":
    main()
