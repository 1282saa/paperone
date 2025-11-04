"""
Learning schemas (Pydantic models)
"""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class SubjectCreate(BaseModel):
    """ü© Ý1"""

    name: str
    color: str | None = None


class SubjectResponse(BaseModel):
    """ü© Qõ"""

    id: UUID
    name: str
    color: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class LearningSessionCreate(BaseModel):
    """Yµ 8X Ý1"""

    subject_id: UUID
    session_type: str
    notes: str | None = None


class LearningSessionResponse(BaseModel):
    """Yµ 8X Qõ"""

    id: UUID
    subject_id: UUID
    session_type: str
    duration_minutes: int
    notes: str | None
    started_at: datetime
    ended_at: datetime | None

    model_config = {"from_attributes": True}


class BlankSheetCreate(BaseModel):
    """1À õµ Ý1"""

    subject_id: UUID
    title: str
    content: str | None = None


class BlankSheetResponse(BaseModel):
    """1À õµ Qõ"""

    id: UUID
    subject_id: UUID
    title: str
    content: str | None
    review_count: int
    last_reviewed_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}
