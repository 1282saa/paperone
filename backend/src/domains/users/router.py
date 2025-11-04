"""
Users domain router
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ...core.database import get_db
from ...dependencies import CurrentUser
from .schemas import UserProfileUpdate, UserResponse

router = APIRouter()


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: CurrentUser):
    """현재 사용자 정보 조회"""
    return current_user


@router.patch("/me/profile", response_model=UserResponse)
async def update_profile(
    profile_update: UserProfileUpdate,
    current_user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """프로필 업데이트"""
    if not current_user.profile:
        return current_user

    # Update profile fields
    for field, value in profile_update.model_dump(exclude_unset=True).items():
        setattr(current_user.profile, field, value)

    await db.commit()
    await db.refresh(current_user)

    return current_user
