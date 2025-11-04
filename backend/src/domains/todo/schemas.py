"""
Todo schemas (Pydantic models)
"""
from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel


class DailyTaskCreate(BaseModel):
    """할 일 생성"""

    title: str
    description: str | None = None
    task_date: date
    category: str | None = None


class DailyTaskResponse(BaseModel):
    """할 일 응답"""

    id: UUID
    title: str
    description: str | None
    task_date: date
    is_completed: bool
    completed_at: datetime | None
    category: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class DailyTaskUpdate(BaseModel):
    """할 일 업데이트"""

    title: str | None = None
    description: str | None = None
    is_completed: bool | None = None
