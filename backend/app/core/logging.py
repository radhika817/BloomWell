import logging
import re
from typing import Any, Dict, List, Set, Union
from pythonjsonlogger.json import JsonFormatter

SENSITIVE_KEYWORDS: Set[str] = {
    "password",
    "token",
    "journal",
    "body",
    "notes",
    "email",
    "authorization",
}

# Regex to catch sensitive key-value pairs or tokens in raw text strings
BEARER_PATTERN = re.compile(r"(Bearer\s+)[A-Za-z0-9\-_.~+/]+=*", re.IGNORECASE)
KEY_VALUE_PATTERN = re.compile(
    r"(?i)\b(password|token|journal|body|notes|email|authorization)\b\s*[:=]\s*['\"]?([^'\",\s]+)['\"]?"
)


EMAIL_PATTERN = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")


def is_sensitive_key(key: str) -> bool:
    """Check if a dictionary key contains any sensitive keywords."""
    key_lower = str(key).lower()
    return any(keyword in key_lower for keyword in SENSITIVE_KEYWORDS)


def redact_string(val: str) -> str:
    """Redact known sensitive patterns inside a text string."""
    redacted = BEARER_PATTERN.sub(r"\1[REDACTED]", val)
    redacted = KEY_VALUE_PATTERN.sub(r"\1=[REDACTED]", redacted)
    redacted = EMAIL_PATTERN.sub("[REDACTED]", redacted)
    return redacted


def redact_data(data: Any) -> Any:
    """Recursively redact dictionaries, lists, and strings."""
    if isinstance(data, dict):
        redacted_dict: Dict[str, Any] = {}
        for k, v in data.items():
            if is_sensitive_key(k):
                redacted_dict[k] = "[REDACTED]"
            else:
                redacted_dict[k] = redact_data(v)
        return redacted_dict
    elif isinstance(data, list):
        return [redact_data(item) for item in data]
    elif isinstance(data, str):
        return redact_string(data)
    return data


class SensitiveDataFilter(logging.Filter):
    """
    Log filter that redacts sensitive attributes from the LogRecord before formatting.
    Ensures that fields named like password, token, journal, body, notes, email, authorization
    are never emitted in plain text.
    """

    def filter(self, record: logging.LogRecord) -> bool:
        # Redact msg if string
        if isinstance(record.msg, str):
            record.msg = redact_string(record.msg)
        elif isinstance(record.msg, dict):
            record.msg = redact_data(record.msg)

        # Redact args if present
        if record.args:
            if isinstance(record.args, dict):
                record.args = redact_data(record.args)
            elif isinstance(record.args, tuple):
                record.args = tuple(
                    redact_data(arg) if isinstance(arg, (dict, list, str)) else arg
                    for arg in record.args
                )

        # Redact extra record attributes
        for attr, value in list(record.__dict__.items()):
            if is_sensitive_key(attr):
                setattr(record, attr, "[REDACTED]")
            elif isinstance(value, (dict, list)):
                setattr(record, attr, redact_data(value))

        return True


class RedactingJsonFormatter(JsonFormatter):
    """JSON formatter that enforces recursive redaction of sensitive fields."""

    def process_log_record(self, log_record: Dict[str, Any]) -> Dict[str, Any]:
        redacted = redact_data(log_record)
        return super().process_log_record(redacted)


def setup_logging(log_level: str = "INFO") -> None:
    """Configure structured JSON logging for the application."""
    root_logger = logging.getLogger()
    root_logger.setLevel(log_level.upper())

    # Remove existing handlers to avoid duplicates
    for handler in list(root_logger.handlers):
        root_logger.removeHandler(handler)

    handler = logging.StreamHandler()
    formatter = RedactingJsonFormatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s"
    )
    handler.setFormatter(formatter)
    handler.addFilter(SensitiveDataFilter())

    root_logger.addHandler(handler)
