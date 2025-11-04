"""
Calendar domain models - D-Day 및 일정 관리
"""
from datetime import date, datetime
from uuid import UUID, uuid4

from sqlalchemy import Date, DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ...core.database import Base


class DDay(Base):
    """D-Day 목표"""

    __tablename__ = "ddays"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)

    title: Mapped[str] = mapped_column(String(100), nullable=False)  # '수능', '중간고사', etc.
    target_date: Mapped[date] = mapped_column(Date, nullable=False)
    color: Mapped[str | None] = mapped_column(String(20), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class StudySchedule(Base):
    """학습 일정"""

    __tablename__ = "study_schedules"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    schedule_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    # 시간
    start_time: Mapped[str | None] = mapped_column(String(10), nullable=True)  # 'HH:MM'
    end_time: Mapped[str | None] = mapped_column(String(10), nullable=True)  # 'HH:MM'

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
