"""
User schemas (Pydantic models)
"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr


class UserProfileResponse(BaseModel):
    """사용자 프로필 응답"""

    university: str | None
    department: str | None
    semester: str | None
    subscription_tier: str
    profile_image_url: str | None
    total_study_days: int
    current_streak: int
    longest_streak: int

    model_config = {"from_attributes": True}


class UserResponse(BaseModel):
    """사용자 응답"""

    id: UUID
    email: EmailStr
    name: str
    is_active: bool
    created_at: datetime
    profile: UserProfileResponse | None = None

    model_config = {"from_attributes": True}


class UserProfileUpdate(BaseModel):
    """프로필 업데이트"""

    university: str | None = None
    department: str | None = None
    semester: str | None = None
    profile_image_url: str | None = None
