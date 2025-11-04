"""
Subjects domain router - 과목 및 문서 API (DynamoDB)
"""
from typing import List

from fastapi import APIRouter, Depends, status, UploadFile, File
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import json

from ...dependencies import CurrentUser
from .schemas import (
    DocumentCreate,
    DocumentResponse,
    DocumentUpdate,
    SubjectCreate,
    SubjectResponse,
    SubjectUpdate,
)
from .service import DocumentService, SubjectService


class TextCorrectionRequest(BaseModel):
    original_text: str

router = APIRouter()


# Subject Endpoints

@router.post("", response_model=SubjectResponse, status_code=status.HTTP_201_CREATED)
async def create_subject(
    subject_data: SubjectCreate,
    current_user: CurrentUser,
):
    """과목 생성"""
    service = SubjectService()
    subject = service.create_subject(current_user.id, subject_data)
    return subject


@router.get("", response_model=List[SubjectResponse])
async def get_my_subjects(
    current_user: CurrentUser,
):
    """내 과목 목록 조회"""
    service = SubjectService()
    subjects = service.get_user_subjects(current_user.id)
    return subjects


@router.get("/{subject_id}", response_model=SubjectResponse)
async def get_subject_detail(
    subject_id: str,
    current_user: CurrentUser,
):
    """과목 상세 조회"""
    service = SubjectService()
    subject = service.get_subject_by_id(current_user.id, subject_id)
    return subject


@router.patch("/{subject_id}", response_model=SubjectResponse)
async def update_subject(
    subject_id: str,
    subject_data: SubjectUpdate,
    current_user: CurrentUser,
):
    """과목 정보 수정"""
    service = SubjectService()
    subject = service.update_subject(current_user.id, subject_id, subject_data)
    return subject


@router.delete("/{subject_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_subject(
    subject_id: str,
    current_user: CurrentUser,
):
    """과목 삭제"""
    service = SubjectService()
    service.delete_subject(current_user.id, subject_id)


# Document Endpoints

@router.post("/documents", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
async def create_document(
    document_data: DocumentCreate,
    current_user: CurrentUser,
):
    """문서 생성"""
    service = DocumentService()
    document = service.create_document(current_user.id, document_data)
    return document


@router.get("/{subject_id}/documents", response_model=List[DocumentResponse])
async def get_subject_documents(
    subject_id: str,
    current_user: CurrentUser,
):
    """특정 과목의 문서 목록 조회"""
    service = DocumentService()
    documents = service.get_subject_documents(current_user.id, subject_id)
    return documents


@router.get("/documents/{document_id}", response_model=DocumentResponse)
async def get_document_detail(
    document_id: str,
    current_user: CurrentUser,
):
    """문서 상세 조회"""
    service = DocumentService()
    document = service.get_document_by_id(current_user.id, document_id)
    return document


@router.patch("/documents/{document_id}", response_model=DocumentResponse)
async def update_document(
    document_id: str,
    document_data: DocumentUpdate,
    current_user: CurrentUser,
):
    """문서 정보 수정"""
    service = DocumentService()
    document = service.update_document(current_user.id, document_id, document_data)
    return document


@router.delete("/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    document_id: str,
    current_user: CurrentUser,
):
    """문서 삭제"""
    service = DocumentService()
    service.delete_document(current_user.id, document_id)


@router.patch("/documents/{document_id}/review", response_model=DocumentResponse)
async def toggle_review_status(
    document_id: str,
    current_user: CurrentUser,
):
    """문서 복습 완료 상태 토글"""
    service = DocumentService()
    document = service.toggle_review_status(current_user.id, document_id)
    return document


@router.get("/reviews")
async def get_review_documents(
    current_user: CurrentUser,
):
    """복습 문서 조회 (오늘의 복습, 밀린 복습)"""
    service = DocumentService()
    reviews = service.get_review_documents(current_user.id)
    return reviews


@router.post("/documents/{document_id}/ai-correction")
async def ai_text_correction(
    document_id: str,
    request: TextCorrectionRequest,
    current_user: CurrentUser,
):
    """AI를 사용하여 문서 텍스트 교정"""
    service = DocumentService()
    result = await service.ai_text_correction(current_user.id, document_id, request.original_text)
    return result


@router.post("/documents/{document_id}/ai-correction-stream")
async def ai_text_correction_stream(
    document_id: str,
    request: TextCorrectionRequest,
    current_user: CurrentUser,
):
    """AI를 사용하여 문서 텍스트 교정 (스트리밍)"""
    service = DocumentService()

    async def generate():
        async for chunk in service.ai_text_correction_stream(current_user.id, document_id, request.original_text):
            yield f"data: {json.dumps({'text': chunk})}\n\n"
        yield f"data: {json.dumps({'done': True})}\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no"
        }
    )


# S3 Upload Endpoint

@router.post("/upload-image")
async def upload_image(
    current_user: CurrentUser,
    file: UploadFile = File(...),
):
    """이미지를 S3에 업로드하고 URL 반환"""
    service = DocumentService()
    image_url = await service.upload_image_to_s3(current_user.id, file)
    return {"image_url": image_url}
