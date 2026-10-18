import pytest
from app.core.config import Settings


def test_production_secret_key_placeholder_rejected():
    """Verify that settings validation rejects placeholder APP_SECRET_KEY in production."""
    with pytest.raises(ValueError, match="APP_SECRET_KEY must be configured with a secure, non-placeholder secret"):
        Settings(
            APP_ENV="production",
            APP_SECRET_KEY="replace-with-local-development-secret",
        )


def test_production_secret_key_short_rejected():
    """Verify that short secrets are rejected in production."""
    with pytest.raises(ValueError, match="minimum 32 characters"):
        Settings(
            APP_ENV="production",
            APP_SECRET_KEY="short-secret",
        )


def test_production_secret_key_valid_accepted():
    """Verify that a strong 32+ character key is accepted in production."""
    secure_key = "a-very-strong-and-secure-random-secret-key-32-chars!"
    config = Settings(
        APP_ENV="production",
        APP_SECRET_KEY=secure_key,
    )
    assert config.APP_SECRET_KEY == secure_key


def test_development_placeholder_allowed():
    """Verify that development environment allows default placeholder key for local ergonomics."""
    config = Settings(
        APP_ENV="development",
        APP_SECRET_KEY="replace-with-local-development-secret",
    )
    assert config.APP_SECRET_KEY == "replace-with-local-development-secret"


def test_cors_origins_parsing():
    """Verify CORS_ORIGINS parses comma-separated string into list."""
    config = Settings(CORS_ORIGINS="http://localhost:3000, https://app.bloomwell.org")
    assert config.cors_origins_list == [
        "http://localhost:3000",
        "https://app.bloomwell.org",
    ]
