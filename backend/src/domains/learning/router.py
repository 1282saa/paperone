"""
Learning domain router - 백지복습 및 학습 세션
"""
from fastapi import APIRouter

router = APIRouter()


@router.get("/subjects")
async def list_subjects():
    """과목 목록 조회"""
    return {"message": "과목 목록 - 구현 예정"}


@router.post("/subjects")
async def create_subject():
    """과목 생성"""
    return {"message": "과목 생성 - 구현 예정"}


@router.get("/sessions")
async def list_sessions():
    """학습 세션 목록"""
    return {"message": "학습 세션 목록 - 구현 예정"}


@router.post("/sessions")
async def create_session():
    """학습 세션 시작"""
    return {"message": "학습 세션 시작 - 구현 예정"}


@router.patch("/sessions/{session_id}/end")
async def end_session(session_id: str):
    """학습 세션 종료"""
    return {"message": f"세션 {session_id} 종료 - 구현 예정"}


@router.get("/blank-sheets")
async def list_blank_sheets():
    """백지 복습 목록"""
    return {"message": "백지 복습 목록 - 구현 예정"}


@router.post("/blank-sheets")
async def create_blank_sheet():
    """백지 복습 생성"""
    return {"message": "백지 복습 생성 - 구현 예정"}


@router.post("/blank-sheets/{sheet_id}/review")
async def review_blank_sheet(sheet_id: str):
    """백지 복습 실행"""
    return {"message": f"백지 {sheet_id} 복습 - 구현 예정"}
