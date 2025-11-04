"""
AI domain models - AI 문제 생성 및 튜터
"""
from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from ...core.database import Base


class AIGeneratedQuestion(Base):
    """AI 생성 문제"""

    __tablename__ = "ai_generated_questions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    subject_id: Mapped[str | None] = mapped_column(String(36), nullable=True)

    question_type: Mapped[str] = mapped_column(String(50), nullable=False)  # '객관식', '주관식', '서술형'
    question_text: Mapped[str] = mapped_column(Text, nullable=False)
    answer: Mapped[str] = mapped_column(Text, nullable=False)
    explanation: Mapped[str | None] = mapped_column(Text, nullable=True)

    # 난이도
    difficulty: Mapped[str | None] = mapped_column(String(20), nullable=True)  # 'easy', 'medium', 'hard'

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class AITutorConversation(Base):
    """AI 튜터 대화 기록"""

    __tablename__ = "ai_tutor_conversations"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), nullable=False)

    conversation_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    role: Mapped[str] = mapped_column(String(20), nullable=False)  # 'user', 'assistant'
    message: Mapped[str] = mapped_column(Text, nullable=False)

    # 토큰 사용량 (옵션)
    token_count: Mapped[int | None] = mapped_column(Integer, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
