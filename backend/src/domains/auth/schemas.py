"""
Auth schemas (Pydantic models)
"""
from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    """Login request schema"""

    email: EmailStr
    password: str = Field(..., min_length=8)


class RegisterRequest(BaseModel):
    """Register request schema"""

    email: EmailStr
    password: str = Field(..., min_length=8)
    name: str = Field(..., min_length=2, max_length=100)


class TokenResponse(BaseModel):
    """Token response schema"""

    access_token: str
    id_token: str | None = None
    refresh_token: str | None = None
    token_type: str = "bearer"
