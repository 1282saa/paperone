"""
User domain models - 학습 플랫폼
"""
from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.dialects.postgresql import UUID as PostgreSQLUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ...core.database import Base


class User(Base):
    """사용자 모델"""

    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    profile: Mapped["UserProfile"] = relationship("UserProfile", back_populates="user", uselist=False)
    learning_sessions: Mapped[list["LearningSession"]] = relationship("LearningSession", back_populates="user")
    daily_tasks: Mapped[list["DailyTask"]] = relationship("DailyTask", back_populates="user")


class UserProfile(Base):
    """사용자 프로필"""

    __tablename__ = "user_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), unique=True, nullable=False)

    # 학교 정보
    university: Mapped[str | None] = mapped_column(String(100), nullable=True)
    department: Mapped[str | None] = mapped_column(String(100), nullable=True)
    semester: Mapped[str | None] = mapped_column(String(20), nullable=True)  # '25-2학기'

    # 구독 정보
    subscription_tier: Mapped[str] = mapped_column(String(20), default='free')  # 'free', 'pro'
    subscription_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # 프로필 이미지
    profile_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # 학습 통계
    total_study_days: Mapped[int] = mapped_column(Integer, default=0)
    current_streak: Mapped[int] = mapped_column(Integer, default=0)
    longest_streak: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="profile")


# Import for relationship type hints
from ..learning.models import LearningSession  # noqa: E402
from ..todo.models import DailyTask  # noqa: E402
