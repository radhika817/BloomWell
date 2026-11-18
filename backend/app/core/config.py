from functools import lru_cache
from typing import List, Optional, Union
from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application configuration loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    APP_ENV: str = "development"
    DATABASE_URL: str = "postgresql+psycopg://bloomwell:change-me@localhost:5432/bloomwell"
    APP_SECRET_KEY: str = "replace-with-local-development-secret"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    CORS_ORIGINS: Union[str, List[str]] = "http://localhost:3000"
    LOG_LEVEL: str = "INFO"
    AI_PROVIDER: str = "disabled"
    ENABLE_DOCS: Optional[bool] = None
    TRUSTED_PROXY_IPS: Union[str, List[str]] = "127.0.0.1,::1"
    ALLOW_DEMO_RESOURCES: Optional[bool] = None
    ALLOW_DRAFT_CONTENT: Optional[bool] = None
    RESOURCE_STALE_DAYS: int = 180
    EXPORT_MAX_RECORDS: int = 50000
    BACKUP_RETENTION_DAYS: int = 14

    @property
    def cors_origins_list(self) -> List[str]:
        """Parse CORS_ORIGINS string or list into a list of allowed origins."""
        if isinstance(self.CORS_ORIGINS, list):
            return self.CORS_ORIGINS
        return [
            origin.strip()
            for origin in self.CORS_ORIGINS.split(",")
            if origin.strip()
        ]

    @property
    def trusted_proxy_ips_list(self) -> List[str]:
        """Parse TRUSTED_PROXY_IPS string or list into a list of trusted proxy IPs."""
        if isinstance(self.TRUSTED_PROXY_IPS, list):
            return self.TRUSTED_PROXY_IPS
        return [
            ip.strip()
            for ip in self.TRUSTED_PROXY_IPS.split(",")
            if ip.strip()
        ]

    @model_validator(mode="after")
    def validate_production_settings(self) -> "Settings":
        """Refuse to start in production if security rules are violated and configure defaults."""
        is_production = self.APP_ENV.lower() in ("production", "prod")

        # ENABLE_DOCS defaults to False in production, True in development if not explicitly set
        if self.ENABLE_DOCS is None:
            self.ENABLE_DOCS = False if is_production else True

        if is_production:
            val = self.APP_SECRET_KEY.strip()
            val_lower = val.lower()
            placeholders = [
                "replace-with",
                "change-me",
                "placeholder",
            ]
            if (
                not val
                or any(ph in val_lower for ph in placeholders)
                or val_lower in ("secret", "default")
                or len(val) < 32
            ):
                raise ValueError(
                    "APP_SECRET_KEY must be configured with a secure, non-placeholder secret in production (minimum 32 characters)."
                )

            # DATABASE_URL must not contain placeholder password
            db_url_lower = self.DATABASE_URL.lower()
            if any(ph in db_url_lower for ph in ("change-me", "replace-with", "placeholder")):
                raise ValueError(
                    "DATABASE_URL must not contain placeholder credentials in production."
                )

            # CORS_ORIGINS must not contain wildcard "*"
            if "*" in self.cors_origins_list:
                raise ValueError(
                    "CORS_ORIGINS must not contain '*' in production."
                )

            # In production, demo resources and draft content default to False unless explicitly set
            if self.ALLOW_DEMO_RESOURCES is None:
                self.ALLOW_DEMO_RESOURCES = False
            if self.ALLOW_DRAFT_CONTENT is None:
                self.ALLOW_DRAFT_CONTENT = False
        else:
            if self.ALLOW_DEMO_RESOURCES is None:
                self.ALLOW_DEMO_RESOURCES = True
            if self.ALLOW_DRAFT_CONTENT is None:
                self.ALLOW_DRAFT_CONTENT = True

        return self


@lru_cache()
def get_settings() -> Settings:
    """Return cached application settings."""
    return Settings()


settings = get_settings()
