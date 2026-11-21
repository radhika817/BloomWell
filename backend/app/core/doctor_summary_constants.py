"""Constants and wording safeguards for the Doctor-visit Summary."""

# Standard neutral questions for clinician discussion (no diagnosis or treatment implied)
DOCTOR_SUMMARY_QUESTIONS = [
    "What are safe, practical ways to manage symptom discomfort when it occurs?",
    "Are there specific details or symptoms that would be most helpful for me to log?",
    "How might daily sleep, hydration, or stress habits relate to what I am noticing?",
    "Under what circumstances or changes should I schedule a follow-up check-up?",
    "Are there non-urgent questions or topics we should plan to discuss at our next visit?",
    "What general wellness resources or self-care steps do you recommend for my situation?",
]

# Standard mandatory closing disclaimer
DOCTOR_SUMMARY_DISCLAIMER = (
    "This summary was created by the person from the dates and symptoms they recorded themselves. "
    "It is not a medical record, an assessment or a diagnosis."
)

# Forbidden diagnostic and medical claim words/substrings
FORBIDDEN_WORDS = [
    "ovulation",
    "fertile",
    "pregnan",
    "abnormal",
    "irregular",
    "indicates",
    "suggests",
    "you have",
    "likely",
    "probably",
]
