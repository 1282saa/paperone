"""
Subject domain models for DynamoDB - 과목 및 문서 관리
"""
from datetime import datetime
from typing import Optional
from uuid import uuid4

from pydantic import BaseModel, Field


class Subject(BaseModel):
    """과목 모델 - DynamoDB"""
    
    # DynamoDB Keys
    PK: str = Field(default="", description="Partition Key: USER#{user_id}")
    SK: str = Field(default="", description="Sort Key: SUBJECT#{subject_id}")
    
    # Attributes
    subject_id: str = Field(default_factory=lambda: str(uuid4()))
    user_id: str
    name: str = Field(..., min_length=1, max_length=100)
    color: str = Field(default='#E8E8FF', max_length=20)
    description: Optional[str] = None
    
    # Statistics
    total_documents: int = Field(default=0)
    total_pages: int = Field(default=0)
    
    # Timestamps
    created_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    
    # Type for queries
    entity_type: str = Field(default="SUBJECT")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
    
    def to_dynamodb_item(self) -> dict:
        """Convert to DynamoDB item format"""
        self.PK = f"USER#{self.user_id}"
        self.SK = f"SUBJECT#{self.subject_id}"
        return self.model_dump()
    
    @classmethod
    def from_dynamodb_item(cls, item: dict) -> "Subject":
        """Create from DynamoDB item"""
        return cls(**item)


class Document(BaseModel):
    """문서 모델 - DynamoDB"""
    
    # DynamoDB Keys
    PK: str = Field(default="", description="Partition Key: SUBJECT#{subject_id}")
    SK: str = Field(default="", description="Sort Key: DOCUMENT#{document_id}")
    
    # Attributes
    document_id: str = Field(default_factory=lambda: str(uuid4()))
    subject_id: str
    user_id: str
    title: str = Field(..., min_length=1, max_length=200)
    
    # OCR Data
    extracted_text: Optional[str] = None
    original_filename: Optional[str] = None
    
    # File Info
    image_url: Optional[str] = None  # Public S3 URL (영구 저장)
    thumbnail_url: Optional[str] = None
    file_size: Optional[int] = None
    pages: int = Field(default=1, ge=1)
    
    # Review Info
    review_count: int = Field(default=0)
    review_completed: bool = Field(default=False)
    last_reviewed_at: Optional[str] = None
    next_review_at: Optional[str] = None
    
    # Timestamps
    created_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    
    # Type for queries
    entity_type: str = Field(default="DOCUMENT")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
    
    def to_dynamodb_item(self) -> dict:
        """Convert to DynamoDB item format"""
        self.PK = f"SUBJECT#{self.subject_id}"
        self.SK = f"DOCUMENT#{self.document_id}"
        return self.model_dump()
    
    @classmethod
    def from_dynamodb_item(cls, item: dict) -> "Document":
        """Create from DynamoDB item"""
        return cls(**item)
