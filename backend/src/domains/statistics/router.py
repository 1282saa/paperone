"""
Statistics domain router - 학습 통계
"""
from fastapi import APIRouter

router = APIRouter()


@router.get("/home")
async def get_home_statistics():
    """홈 화면 통계"""
    return {
        "current_streak": 5,
        "total_study_days": 42,
        "weekly_consistency_rate": 0.82,
        "today_tasks_count": 4,
        "dday_info": {"title": "수능", "days_remaining": 297}
    }


@router.get("/daily")
async def get_daily_statistics():
    """일별 통계 조회"""
    return {"message": "일별 통계 - 구현 예정"}


@router.get("/weekly")
async def get_weekly_statistics():
    """주간 통계 조회"""
    return {"message": "주간 통계 - 구현 예정"}
