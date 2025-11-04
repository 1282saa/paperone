"""
Todo domain router - 오늘의 할 일
"""
from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def list_daily_tasks():
    """오늘의 할 일 목록"""
    return {"message": "오늘의 할 일 목록 - 구현 예정"}


@router.post("/")
async def create_daily_task():
    """할 일 생성"""
    return {"message": "할 일 생성 - 구현 예정"}


@router.patch("/{task_id}")
async def update_task(task_id: str):
    """할 일 업데이트"""
    return {"message": f"할 일 {task_id} 업데이트 - 구현 예정"}


@router.post("/{task_id}/complete")
async def complete_task(task_id: str):
    """할 일 완료"""
    return {"message": f"할 일 {task_id} 완료 - 구현 예정"}


@router.delete("/{task_id}")
async def delete_task(task_id: str):
    """할 일 삭제"""
    return {"message": f"할 일 {task_id} 삭제 - 구현 예정"}
