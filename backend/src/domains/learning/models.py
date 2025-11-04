"""
Learning domain models - 백지복습 및 학습 세션
"""
from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ...core.database import Base


class Subject(Base):
    """과목"""

    __tablename__ = "subjects"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    color: Mapped[str | None] = mapped_column(String(20), nullable=True)  # 색상 코드

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    learning_sessions: Mapped[list["LearningSession"]] = relationship("LearningSession", back_populates="subject")
    sheets: Mapped[list["BlankSheet"]] = relationship("BlankSheet", back_populates="subject")


class LearningSession(Base):
    """학습 세션"""

    __tablename__ = "learning_sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    subject_id: Mapped[UUID] = mapped_column(ForeignKey("subjects.id"), nullable=False)

    # 세션 정보
    session_type: Mapped[str] = mapped_column(String(50), nullable=False)  # '백지복습', '문제풀이', '강의듣기'
    duration_minutes: Mapped[int] = mapped_column(Integer, default=0)  # 학습 시간 (분)

    # 메모
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="learning_sessions")
    subject: Mapped["Subject"] = relationship("Subject", back_populates="learning_sessions")


class BlankSheet(Base):
    """백지 복습 시트"""

    __tablename__ = "blank_sheets"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    subject_id: Mapped[UUID] = mapped_column(ForeignKey("subjects.id"), nullable=False)

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    content: Mapped[str | None] = mapped_column(Text, nullable=True)  # 백지 내용

    # 복습 통계
    review_count: Mapped[int] = mapped_column(Integer, default=0)
    last_reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    subject: Mapped["Subject"] = relationship("Subject", back_populates="sheets")


# Import for relationship type hints
from ..users.models import User  # noqa: E402
