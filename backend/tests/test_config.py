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


def test_helphub_and_education_defaults_in_development():
    """Verify demo resources and draft content default to True in development."""
    config = Settings(APP_ENV="development")
    assert config.ALLOW_DEMO_RESOURCES is True
    assert config.ALLOW_DRAFT_CONTENT is True
    assert config.RESOURCE_STALE_DAYS == 180


def test_helphub_and_education_defaults_in_production():
    """Verify demo resources and draft content are strictly False in production."""
    secure_key = "a-very-strong-and-secure-random-secret-key-32-chars!"
    config = Settings(
        APP_ENV="production",
        APP_SECRET_KEY=secure_key,
    )
    assert config.ALLOW_DEMO_RESOURCES is False
    assert config.ALLOW_DRAFT_CONTENT is False
    assert config.RESOURCE_STALE_DAYS == 180


def test_privacy_and_retention_defaults():
    """Verify default export record cap and backup retention days."""
    config = Settings(
        APP_ENV="development",
        APP_SECRET_KEY="replace-with-local-development-secret",
    )
    assert config.EXPORT_MAX_RECORDS == 50000
    assert config.BACKUP_RETENTION_DAYS == 14

    custom = Settings(
        APP_ENV="development",
        APP_SECRET_KEY="replace-with-local-development-secret",
        EXPORT_MAX_RECORDS=1000,
        BACKUP_RETENTION_DAYS=30,
    )
    assert custom.EXPORT_MAX_RECORDS == 1000
    assert custom.BACKUP_RETENTION_DAYS == 30


def test_helphub_and_education_production_overrides_to_false():
    """Verify that even if True is passed for demo/draft, production enforces False."""
    secure_key = "a-very-strong-and-secure-random-secret-key-32-chars!"
    config = Settings(
        APP_ENV="production",
        APP_SECRET_KEY=secure_key,
        ALLOW_DEMO_RESOURCES=True,
        ALLOW_DRAFT_CONTENT=True,
    )
    assert config.ALLOW_DEMO_RESOURCES is False
    assert config.ALLOW_DRAFT_CONTENT is False


def test_resource_stale_days_custom_value():
    """Verify RESOURCE_STALE_DAYS can be customized."""
    config = Settings(RESOURCE_STALE_DAYS=90)
    assert config.RESOURCE_STALE_DAYS == 90
