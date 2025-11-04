"""
Subject domain schemas - 과목 및 문서 Pydantic 모델
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# Subject Schemas

class SubjectBase(BaseModel):
    """과목 기본 스키마"""
    name: str = Field(..., min_length=1, max_length=100, description="과목명")
    color: str = Field(default='#E8E8FF', max_length=20, description="배경색")
    description: Optional[str] = Field(None, description="과목 설명")


class SubjectCreate(SubjectBase):
    """과목 생성 스키마"""
    pass


class SubjectUpdate(BaseModel):
    """과목 수정 스키마"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    color: Optional[str] = Field(None, max_length=20)
    description: Optional[str] = None


class SubjectResponse(SubjectBase):
    """과목 응답 스키마"""
    subject_id: str
    user_id: str
    total_documents: int = 0
    total_pages: int = 0
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True


# Document Schemas

class DocumentBase(BaseModel):
    """문서 기본 스키마"""
    title: str = Field(..., min_length=1, max_length=200, description="문서 제목")
    extracted_text: Optional[str] = Field(None, description="OCR 추출 텍스트")
    pages: int = Field(default=1, ge=1, description="페이지 수")


class DocumentCreate(DocumentBase):
    """문서 생성 스키마"""
    subject_id: str = Field(..., description="과목 ID")
    original_filename: Optional[str] = None
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    file_size: Optional[int] = None


class DocumentUpdate(BaseModel):
    """문서 수정 스키마"""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    extracted_text: Optional[str] = None
    pages: Optional[int] = Field(None, ge=1)
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None


class DocumentResponse(DocumentBase):
    """문서 응답 스키마"""
    document_id: str
    subject_id: str
    user_id: str
    original_filename: Optional[str] = None
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    file_size: Optional[int] = None
    review_count: int = 0
    review_completed: bool = False
    last_reviewed_at: Optional[str] = None
    next_review_at: Optional[str] = None
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True


class SubjectWithDocuments(SubjectResponse):
    """과목 + 문서 리스트 응답 스키마"""
    documents: list[DocumentResponse] = []

    class Config:
        from_attributes = True
