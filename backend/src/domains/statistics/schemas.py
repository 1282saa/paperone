"""
Statistics schemas (Pydantic models)
"""
from datetime import date
from pydantic import BaseModel


class DailyStatisticsResponse(BaseModel):
    """일별 통계 응답"""

    stat_date: date
    total_study_minutes: int
    completed_tasks: int
    completed_reviews: int
    completed_sessions: int
    did_study: bool

    model_config = {"from_attributes": True}


class WeeklyStatisticsResponse(BaseModel):
    """주간 통계 응답"""

    week_start: date
    total_study_minutes: int
    study_days: int
    consistency_rate: float  # 복습 지속률
    daily_stats: list[DailyStatisticsResponse]


class HomeStatisticsResponse(BaseModel):
    """홈 화면 통계"""

    current_streak: int
    total_study_days: int
    weekly_consistency_rate: float  # 최근 7일 복습 지속률
    today_tasks_count: int
    dday_info: dict | None  # {"title": "수능", "days_remaining": 297}
