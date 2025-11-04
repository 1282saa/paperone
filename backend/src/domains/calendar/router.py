"""
Calendar domain router - D-Day 및 일정 관리
"""
from fastapi import APIRouter

router = APIRouter()


@router.get("/ddays")
async def list_ddays():
    """D-Day 목록 조회"""
    return {"message": "D-Day 목록 - 구현 예정"}


@router.post("/ddays")
async def create_dday():
    """D-Day 생성"""
    return {"message": "D-Day 생성 - 구현 예정"}


@router.delete("/ddays/{dday_id}")
async def delete_dday(dday_id: str):
    """D-Day 삭제"""
    return {"message": f"D-Day {dday_id} 삭제 - 구현 예정"}


@router.get("/schedules")
async def list_schedules():
    """학습 일정 목록"""
    return {"message": "학습 일정 목록 - 구현 예정"}


@router.post("/schedules")
async def create_schedule():
    """학습 일정 생성"""
    return {"message": "학습 일정 생성 - 구현 예정"}
