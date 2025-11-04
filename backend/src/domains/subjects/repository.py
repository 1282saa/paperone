"""
Subject domain repository - DynamoDB data access layer
"""
import os
from datetime import datetime
from typing import List, Optional

import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError

from .models import Document, Subject

# DynamoDB 리소스 초기화
dynamodb = boto3.resource('dynamodb', region_name=os.getenv('APP_AWS_REGION', os.getenv('AWS_REGION', 'us-east-1')))

SUBJECTS_TABLE = os.getenv('SUBJECTS_TABLE', 'ocr-test-subjects-dev')
DOCUMENTS_TABLE = os.getenv('DOCUMENTS_TABLE', 'ocr-test-documents-dev')


class SubjectRepository:
    """과목 Repository - DynamoDB 데이터 액세스"""
    
    def __init__(self):
        self.table = dynamodb.Table(SUBJECTS_TABLE)
    
    def create(self, subject: Subject) -> Subject:
        """과목 생성"""
        item = subject.to_dynamodb_item()
        
        try:
            self.table.put_item(Item=item)
            return subject
        except ClientError as e:
            raise Exception(f"과목 생성 실패: {e.response['Error']['Message']}")
    
    def get_by_id(self, user_id: str, subject_id: str) -> Optional[Subject]:
        """특정 과목 조회"""
        pk = f"USER#{user_id}"
        sk = f"SUBJECT#{subject_id}"
        
        try:
            response = self.table.get_item(Key={'PK': pk, 'SK': sk})
            item = response.get('Item')
            return Subject.from_dynamodb_item(item) if item else None
        except ClientError as e:
            raise Exception(f"과목 조회 실패: {e.response['Error']['Message']}")
    
    def get_by_user(self, user_id: str) -> List[Subject]:
        """사용자의 모든 과목 조회"""
        try:
            response = self.table.query(
                IndexName='UserIndex',
                KeyConditionExpression=Key('user_id').eq(user_id) & Key('SK').begins_with('SUBJECT#')
            )
            items = response.get('Items', [])
            return [Subject.from_dynamodb_item(item) for item in items]
        except ClientError as e:
            raise Exception(f"과목 목록 조회 실패: {e.response['Error']['Message']}")
    
    def update(self, subject: Subject) -> Subject:
        """과목 정보 수정"""
        subject.updated_at = datetime.utcnow().isoformat()
        item = subject.to_dynamodb_item()
        
        try:
            self.table.put_item(Item=item)
            return subject
        except ClientError as e:
            raise Exception(f"과목 수정 실패: {e.response['Error']['Message']}")
    
    def delete(self, user_id: str, subject_id: str) -> bool:
        """과목 삭제"""
        pk = f"USER#{user_id}"
        sk = f"SUBJECT#{subject_id}"
        
        try:
            self.table.delete_item(Key={'PK': pk, 'SK': sk})
            return True
        except ClientError as e:
            raise Exception(f"과목 삭제 실패: {e.response['Error']['Message']}")
    
    def check_duplicate_name(self, user_id: str, name: str, exclude_id: Optional[str] = None) -> bool:
        """과목명 중복 체크"""
        subjects = self.get_by_user(user_id)
        
        for subject in subjects:
            if exclude_id and subject.subject_id == exclude_id:
                continue
            if subject.name == name:
                return True
        
        return False


class DocumentRepository:
    """문서 Repository - DynamoDB 데이터 액세스"""
    
    def __init__(self):
        self.table = dynamodb.Table(DOCUMENTS_TABLE)
    
    def create(self, document: Document) -> Document:
        """문서 생성"""
        item = document.to_dynamodb_item()
        
        try:
            self.table.put_item(Item=item)
            return document
        except ClientError as e:
            raise Exception(f"문서 생성 실패: {e.response['Error']['Message']}")
    
    def get_by_id(self, subject_id: str, document_id: str) -> Optional[Document]:
        """특정 문서 조회"""
        pk = f"SUBJECT#{subject_id}"
        sk = f"DOCUMENT#{document_id}"
        
        try:
            response = self.table.get_item(Key={'PK': pk, 'SK': sk})
            item = response.get('Item')
            return Document.from_dynamodb_item(item) if item else None
        except ClientError as e:
            raise Exception(f"문서 조회 실패: {e.response['Error']['Message']}")
    
    def get_by_subject(self, subject_id: str) -> List[Document]:
        """특정 과목의 모든 문서 조회"""
        try:
            response = self.table.query(
                IndexName='SubjectIndex',
                KeyConditionExpression=Key('subject_id').eq(subject_id),
                ScanIndexForward=False  # 최신순 정렬
            )
            items = response.get('Items', [])
            return [Document.from_dynamodb_item(item) for item in items]
        except ClientError as e:
            raise Exception(f"문서 목록 조회 실패: {e.response['Error']['Message']}")
    
    def get_by_user(self, user_id: str) -> List[Document]:
        """사용자의 모든 문서 조회"""
        try:
            response = self.table.query(
                IndexName='UserIndex',
                KeyConditionExpression=Key('user_id').eq(user_id),
                ScanIndexForward=False  # 최신순 정렬
            )
            items = response.get('Items', [])
            return [Document.from_dynamodb_item(item) for item in items]
        except ClientError as e:
            raise Exception(f"문서 목록 조회 실패: {e.response['Error']['Message']}")
    
    def update(self, document: Document) -> Document:
        """문서 정보 수정"""
        document.updated_at = datetime.utcnow().isoformat()
        item = document.to_dynamodb_item()
        
        try:
            self.table.put_item(Item=item)
            return document
        except ClientError as e:
            raise Exception(f"문서 수정 실패: {e.response['Error']['Message']}")
    
    def delete(self, subject_id: str, document_id: str) -> bool:
        """문서 삭제"""
        pk = f"SUBJECT#{subject_id}"
        sk = f"DOCUMENT#{document_id}"
        
        try:
            self.table.delete_item(Key={'PK': pk, 'SK': sk})
            return True
        except ClientError as e:
            raise Exception(f"문서 삭제 실패: {e.response['Error']['Message']}")
    
    def count_by_subject(self, subject_id: str) -> int:
        """과목별 문서 수 카운트"""
        documents = self.get_by_subject(subject_id)
        return len(documents)
    
    def sum_pages_by_subject(self, subject_id: str) -> int:
        """과목별 총 페이지 수 계산"""
        documents = self.get_by_subject(subject_id)
        return sum(doc.pages for doc in documents)
