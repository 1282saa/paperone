"""
AI schemas (Pydantic models)
"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class AIQuestionGenerateRequest(BaseModel):
    """AI 문제 생성 요청"""

    subject_id: UUID | None = None
    question_type: str  # '객관식', '주관식', '서술형'
    difficulty: str | None = None
    topic: str | None = None


class AIQuestionResponse(BaseModel):
    """AI 생성 문제 응답"""

    id: UUID
    question_type: str
    question_text: str
    answer: str
    explanation: str | None
    difficulty: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class AITutorRequest(BaseModel):
    """AI 튜터 대화 요청"""

    message: str
    conversation_id: str | None = None


class AITutorResponse(BaseModel):
    """AI 튜터 응답"""

    message: str
    conversation_id: str
