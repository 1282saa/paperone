"""
Core configuration using Pydantic Settings
"""
from functools import lru_cache
from typing import Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings"""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    # App
    APP_NAME: str = "SW Backend API"
    DEBUG: bool = False
    VERSION: str = "1.0.0"

    # DynamoDB Tables (using environment variables from serverless.yml)
    SUBJECTS_TABLE: Optional[str] = None
    DOCUMENTS_TABLE: Optional[str] = None

    # AWS Cognito
    COGNITO_USER_POOL_ID: Optional[str] = None
    COGNITO_CLIENT_ID: Optional[str] = None
    APP_AWS_REGION: str = "us-east-1"

    # Security
    SECRET_KEY: str = Field(default="default-secret-key-must-be-at-least-32-characters-long", min_length=32, description="Secret key for JWT")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours

    # AWS Bedrock
    AWS_REGION: str = "us-east-1"
    BEDROCK_MODEL_ID: str = "anthropic.claude-3-sonnet-20240229-v1:0"

    # OpenAI
    OPENAI_API_KEY: Optional[str] = None
    OPENAI_MODEL: str = "gpt-4o-mini"

    # CORS
    CORS_ORIGINS: list[str] = ["http://localhost:3000", "http://localhost:8000"]

    # Pagination
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


settings = get_settings()
