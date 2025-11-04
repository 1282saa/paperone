"""
Calendar schemas (Pydantic models)
"""
from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel


class DDayCreate(BaseModel):
    """D-Day 생성"""

    title: str
    target_date: date
    color: str | None = None


class DDayResponse(BaseModel):
    """D-Day 응답"""

    id: UUID
    title: str
    target_date: date
    color: str | None
    days_remaining: int | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class StudyScheduleCreate(BaseModel):
    """학습 일정 생성"""

    title: str
    description: str | None = None
    schedule_date: date
    start_time: str | None = None
    end_time: str | None = None


class StudyScheduleResponse(BaseModel):
    """학습 일정 응답"""

    id: UUID
    title: str
    description: str | None
    schedule_date: date
    start_time: str | None
    end_time: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
