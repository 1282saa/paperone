"""
Statistics domain models - 학습 통계
"""
from datetime import date, datetime
from uuid import UUID, uuid4

from sqlalchemy import Date, DateTime, ForeignKey, Integer, func
from sqlalchemy.orm import Mapped, mapped_column

from ...core.database import Base


class DailyStatistics(Base):
    """일별 학습 통계"""

    __tablename__ = "daily_statistics"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    stat_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    # 학습 시간 (분)
    total_study_minutes: Mapped[int] = mapped_column(Integer, default=0)

    # 완료한 활동 수
    completed_tasks: Mapped[int] = mapped_column(Integer, default=0)
    completed_reviews: Mapped[int] = mapped_column(Integer, default=0)
    completed_sessions: Mapped[int] = mapped_column(Integer, default=0)

    # 복습 지속률 계산용
    did_study: Mapped[bool] = mapped_column(default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
