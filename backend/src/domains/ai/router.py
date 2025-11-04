"""
AI domain router - AI 문제 생성 및 튜터
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ...core.database import get_db
from ...dependencies import CurrentUser
from .schemas import AITutorRequest, AITutorResponse
from .service import AIService

router = APIRouter()


@router.post("/tutor", response_model=AITutorResponse)
async def ai_tutor_chat(
    request: AITutorRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """AI 튜터와 대화하기"""
    service = AIService(db)
    return await service.chat_with_tutor(current_user.id, request)


@router.get("/tutor/conversations")
async def list_conversations(
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """사용자의 대화 목록 조회"""
    service = AIService(db)
    conversations = await service.get_user_conversations(current_user.id)
    return {"conversations": conversations}


@router.get("/tutor/conversations/{conversation_id}")
async def get_conversation_detail(
    conversation_id: str,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_db),
):
    """특정 대화의 전체 내용 조회"""
    service = AIService(db)
    messages = await service.get_conversation_detail(current_user.id, conversation_id)
    return {"messages": messages}


# 문제 생성 기능은 추후 구현
@router.post("/generate-question")
async def generate_question():
    """AI 문제 생성 - 추후 구현 예정"""
    return {"message": "AI 문제 생성 - 구현 예정"}


@router.get("/questions")
async def list_generated_questions():
    """생성된 문제 목록 - 추후 구현 예정"""
    return {"message": "생성된 문제 목록 - 구현 예정"}
