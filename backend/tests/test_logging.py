import io
import json
import logging
from app.core.logging import RedactingJsonFormatter, SensitiveDataFilter


def test_sensitive_data_redaction_in_structured_logs():
    """
    Test that fields named like password, token, journal, body, notes, email, authorization
    are strictly redacted and that fake journal strings and fake tokens never appear in captured logs.
    """
    fake_token = "fake-jwt-token-xyz-9876543210"
    fake_journal = "My highly private personal reflections about physical symptoms"
    fake_password = "super-secret-password-123"
    fake_notes = "pain level high today"
    fake_email = "student@university.edu"
    fake_body = "{'sensitive': 'payload'}"

    # Setup an isolated logger with the redacting formatter and filter
    log_stream = io.StringIO()
    handler = logging.StreamHandler(log_stream)
    formatter = RedactingJsonFormatter("%(levelname)s %(message)s")
    handler.setFormatter(formatter)
    handler.addFilter(SensitiveDataFilter())

    test_logger = logging.getLogger("test_redaction_logger")
    test_logger.setLevel(logging.INFO)
    test_logger.handlers = [handler]
    test_logger.propagate = False

    # 1. Log with sensitive data passed as extra attributes
    test_logger.info(
        "User action occurred",
        extra={
            "token": fake_token,
            "journal_entry": fake_journal,
            "password": fake_password,
            "notes": fake_notes,
            "email": fake_email,
            "body": fake_body,
            "non_sensitive_field": "public_value",
        },
    )

    # 2. Log with sensitive data embedded in the message string
    test_logger.info(
        "Header received: Bearer %s with token: %s and journal: %s",
        fake_token,
        fake_token,
        fake_journal,
    )

    captured_logs = log_stream.getvalue()

    # CRITICAL ASSERTIONS:
    # Prove that the fake token and fake journal strings NEVER appear anywhere in the captured logs
    assert fake_token not in captured_logs
    assert fake_journal not in captured_logs
    assert fake_password not in captured_logs
    assert fake_notes not in captured_logs
    assert fake_email not in captured_logs
    assert fake_body not in captured_logs

    # Verify that [REDACTED] replaced the sensitive values
    assert "[REDACTED]" in captured_logs

    # Verify that non-sensitive metadata is preserved
    assert "public_value" in captured_logs

    # Verify that each line is valid JSON
    for line in captured_logs.strip().split("\n"):
        if line.strip():
            data = json.loads(line)
            assert isinstance(data, dict)
