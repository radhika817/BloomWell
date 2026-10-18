from functools import lru_cache
from typing import List, Union
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

    @model_validator(mode="after")
    def validate_production_secret(self) -> "Settings":
        """Refuse to start in production if APP_SECRET_KEY is still a placeholder."""
        is_production = self.APP_ENV.lower() in ("production", "prod")
        val = self.APP_SECRET_KEY.strip()
        val_lower = val.lower()
        placeholders = [
            "replace-with",
            "change-me",
            "placeholder",
        ]
        if is_production:
            if (
                not val
                or any(ph in val_lower for ph in placeholders)
                or val_lower in ("secret", "default")
                or len(val) < 32
            ):
                raise ValueError(
                    "APP_SECRET_KEY must be configured with a secure, non-placeholder secret in production (minimum 32 characters)."
                )
        return self


@lru_cache()
def get_settings() -> Settings:
    """Return cached application settings."""
    return Settings()


settings = get_settings()
