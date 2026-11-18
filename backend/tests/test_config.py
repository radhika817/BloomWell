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


def test_helphub_and_education_production_explicit_override_honored():
    """Verify that if True is explicitly passed for demo/draft in production, it is honored."""
    secure_key = "a-very-strong-and-secure-random-secret-key-32-chars!"
    config = Settings(
        APP_ENV="production",
        APP_SECRET_KEY=secure_key,
        DATABASE_URL="postgresql+psycopg://bloomwell:production_pass_123@prod-db.internal:5432/bloomwell",
        CORS_ORIGINS="https://app.bloomwell.org",
        ALLOW_DEMO_RESOURCES=True,
        ALLOW_DRAFT_CONTENT=True,
    )
    assert config.ALLOW_DEMO_RESOURCES is True
    assert config.ALLOW_DRAFT_CONTENT is True


def test_production_database_url_placeholder_rejected():
    """Verify that placeholder database passwords are rejected in production."""
    secure_key = "a-very-strong-and-secure-random-secret-key-32-chars!"
    with pytest.raises(ValueError, match="DATABASE_URL must not contain placeholder credentials"):
        Settings(
            APP_ENV="production",
            APP_SECRET_KEY=secure_key,
            DATABASE_URL="postgresql+psycopg://bloomwell:change-me@localhost:5432/bloomwell",
        )


def test_production_cors_wildcard_rejected():
    """Verify that wildcard CORS origins are rejected in production."""
    secure_key = "a-very-strong-and-secure-random-secret-key-32-chars!"
    with pytest.raises(ValueError, match=r"CORS_ORIGINS must not contain '\*'"):
        Settings(
            APP_ENV="production",
            APP_SECRET_KEY=secure_key,
            DATABASE_URL="postgresql+psycopg://bloomwell:secure_pass_123@prod-db:5432/bloomwell",
            CORS_ORIGINS="*",
        )


def test_production_enable_docs_default():
    """Verify ENABLE_DOCS defaults to False in production, True in dev, with explicit overrides honored."""
    dev_config = Settings(APP_ENV="development")
    assert dev_config.ENABLE_DOCS is True

    secure_key = "a-very-strong-and-secure-random-secret-key-32-chars!"
    prod_config = Settings(
        APP_ENV="production",
        APP_SECRET_KEY=secure_key,
        DATABASE_URL="postgresql+psycopg://bloomwell:secure_pass_123@prod-db:5432/bloomwell",
        CORS_ORIGINS="https://app.bloomwell.org",
    )
    assert prod_config.ENABLE_DOCS is False

    prod_override = Settings(
        APP_ENV="production",
        APP_SECRET_KEY=secure_key,
        DATABASE_URL="postgresql+psycopg://bloomwell:secure_pass_123@prod-db:5432/bloomwell",
        CORS_ORIGINS="https://app.bloomwell.org",
        ENABLE_DOCS=True,
    )
    assert prod_override.ENABLE_DOCS is True


def test_trusted_proxy_ips_config():
    """Verify TRUSTED_PROXY_IPS default and comma-separated list parsing."""
    config = Settings(TRUSTED_PROXY_IPS="127.0.0.1, 10.0.0.1, 192.168.1.1")
    assert config.trusted_proxy_ips_list == ["127.0.0.1", "10.0.0.1", "192.168.1.1"]

    default_config = Settings()
    assert default_config.trusted_proxy_ips_list == ["127.0.0.1", "::1"]


def test_ai_provider_default_disabled():
    """Verify AI_PROVIDER defaults to disabled."""
    config = Settings()
    assert config.AI_PROVIDER == "disabled"


def test_docs_disabled_in_fastapi_app(monkeypatch):
    """Verify FastAPI application does not serve /docs, /redoc, or /openapi.json when ENABLE_DOCS=False."""
    from fastapi.testclient import TestClient
    from app.core import config as config_module
    from app.main import create_application

    monkeypatch.setattr(config_module.settings, "ENABLE_DOCS", False)
    test_app = create_application()
    client = TestClient(test_app)

    assert client.get("/docs").status_code == 404
    assert client.get("/redoc").status_code == 404
    assert client.get("/openapi.json").status_code == 404


def test_resource_stale_days_custom_value():
    """Verify RESOURCE_STALE_DAYS can be customized."""
    config = Settings(RESOURCE_STALE_DAYS=90)
    assert config.RESOURCE_STALE_DAYS == 90
