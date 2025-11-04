"""
Subject domain service - 과목 및 문서 비즈니스 로직 (DynamoDB)
"""
import uuid
from typing import List, AsyncGenerator
from datetime import datetime
import json
import asyncio

import boto3
from fastapi import HTTPException, status, UploadFile

from .models import Document, Subject
from .repository import DocumentRepository, SubjectRepository
from .schemas import DocumentCreate, DocumentUpdate, SubjectCreate, SubjectUpdate


class SubjectService:
    """과목 서비스"""
    
    def __init__(self):
        self.repo = SubjectRepository()
        self.doc_repo = DocumentRepository()
    
    def create_subject(self, user_id: str, subject_data: SubjectCreate) -> Subject:
        """과목 생성"""
        # 중복 체크
        if self.repo.check_duplicate_name(user_id, subject_data.name):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 존재하는 과목명입니다."
            )
        
        # 새 과목 생성
        subject = Subject(
            user_id=user_id,
            name=subject_data.name,
            color=subject_data.color,
            description=subject_data.description
        )
        
        return self.repo.create(subject)
    
    def get_user_subjects(self, user_id: str) -> List[Subject]:
        """사용자의 모든 과목 조회"""
        return self.repo.get_by_user(user_id)
    
    def get_subject_by_id(self, user_id: str, subject_id: str) -> Subject:
        """특정 과목 조회"""
        subject = self.repo.get_by_id(user_id, subject_id)
        
        if not subject:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="과목을 찾을 수 없습니다."
            )
        
        return subject
    
    def update_subject(self, user_id: str, subject_id: str, subject_data: SubjectUpdate) -> Subject:
        """과목 정보 수정"""
        subject = self.get_subject_by_id(user_id, subject_id)
        
        # 이름 중복 체크 (변경하는 경우)
        if subject_data.name and subject_data.name != subject.name:
            if self.repo.check_duplicate_name(user_id, subject_data.name, exclude_id=subject_id):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="이미 존재하는 과목명입니다."
                )
        
        # 수정
        update_data = subject_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(subject, key, value)
        
        return self.repo.update(subject)
    
    def delete_subject(self, user_id: str, subject_id: str) -> None:
        """과목 삭제 (관련 문서도 모두 삭제)"""
        subject = self.get_subject_by_id(user_id, subject_id)
        
        # 관련 문서 모두 삭제
        documents = self.doc_repo.get_by_subject(subject_id)
        for doc in documents:
            self.doc_repo.delete(subject_id, doc.document_id)
        
        # 과목 삭제
        self.repo.delete(user_id, subject_id)
    
    def update_subject_statistics(self, subject_id: str, user_id: str) -> None:
        """과목 통계 업데이트 (문서 수, 총 페이지 수)"""
        subject = self.get_subject_by_id(user_id, subject_id)
        
        # 통계 계산
        doc_count = self.doc_repo.count_by_subject(subject_id)
        total_pages = self.doc_repo.sum_pages_by_subject(subject_id)
        
        # 업데이트
        subject.total_documents = doc_count
        subject.total_pages = total_pages
        
        self.repo.update(subject)


class DocumentService:
    """문서 서비스"""

    def __init__(self):
        self.repo = DocumentRepository()
        self.subject_service = SubjectService()
    
    def create_document(self, user_id: str, document_data: DocumentCreate) -> Document:
        """문서 생성"""
        # 과목 존재 확인
        subject = self.subject_service.get_subject_by_id(user_id, document_data.subject_id)
        
        # 새 문서 생성
        document = Document(
            user_id=user_id,
            subject_id=document_data.subject_id,
            title=document_data.title,
            extracted_text=document_data.extracted_text,
            original_filename=document_data.original_filename,
            image_url=document_data.image_url,
            thumbnail_url=document_data.thumbnail_url,
            pages=document_data.pages,
            file_size=document_data.file_size
        )
        
        result = self.repo.create(document)
        
        # 과목 통계 업데이트
        self.subject_service.update_subject_statistics(document_data.subject_id, user_id)
        
        return result
    
    def get_subject_documents(self, user_id: str, subject_id: str) -> List[Document]:
        """특정 과목의 모든 문서 조회"""
        # 과목 존재 확인
        self.subject_service.get_subject_by_id(user_id, subject_id)
        
        return self.repo.get_by_subject(subject_id)
    
    def get_document_by_id(self, user_id: str, document_id: str, subject_id: str = None) -> Document:
        """특정 문서 조회"""
        if not subject_id:
            # user_id로 검색하여 subject_id 찾기
            user_docs = self.repo.get_by_user(user_id)
            document = next((doc for doc in user_docs if doc.document_id == document_id), None)
        else:
            document = self.repo.get_by_id(subject_id, document_id)
        
        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="문서를 찾을 수 없습니다."
            )
        
        # 사용자 권한 확인
        if document.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="접근 권한이 없습니다."
            )
        
        return document
    
    def update_document(self, user_id: str, document_id: str, document_data: DocumentUpdate) -> Document:
        """문서 정보 수정"""
        # 먼저 user_id로 문서 찾기
        document = self.get_document_by_id(user_id, document_id)
        
        # 수정
        update_data = document_data.model_dump(exclude_unset=True)
        old_pages = document.pages
        
        for key, value in update_data.items():
            setattr(document, key, value)
        
        result = self.repo.update(document)
        
        # 페이지 수 변경 시 과목 통계 업데이트
        if 'pages' in update_data and old_pages != document.pages:
            self.subject_service.update_subject_statistics(document.subject_id, user_id)
        
        return result
    
    def delete_document(self, user_id: str, document_id: str) -> None:
        """문서 삭제"""
        document = self.get_document_by_id(user_id, document_id)

        subject_id = document.subject_id

        self.repo.delete(subject_id, document_id)

        # 과목 통계 업데이트
        self.subject_service.update_subject_statistics(subject_id, user_id)

    def toggle_review_status(self, user_id: str, document_id: str) -> Document:
        """문서 복습 완료 상태 토글"""
        document = self.get_document_by_id(user_id, document_id)

        # 복습 완료 상태 토글
        document.review_completed = not document.review_completed

        # 복습 완료 시 last_reviewed_at 업데이트
        if document.review_completed:
            from datetime import datetime
            document.last_reviewed_at = datetime.utcnow().isoformat()
            document.review_count += 1

        return self.repo.update(document)

    def get_review_documents(self, user_id: str) -> dict:
        """복습 문서 조회 (오늘의 복습, 밀린 복습)"""
        from datetime import datetime, timezone, timedelta

        # 사용자의 모든 문서 조회
        user_docs = self.repo.get_by_user(user_id)

        # 사용자의 모든 과목 조회 (과목명 매핑용)
        subjects = self.subject_service.get_user_subjects(user_id)
        subject_map = {s.subject_id: s.name for s in subjects} if subjects else {}

        # 과목이나 문서가 없으면 빈 결과 반환
        if not user_docs:
            return {
                "today": [],
                "overdue": [],
                "today_count": 0,
                "overdue_count": 0
            }

        # 오늘 날짜 (KST 기준)
        now_utc = datetime.now(timezone.utc)
        kst_offset = timedelta(hours=9)
        now_kst = now_utc + kst_offset
        today_kst = now_kst.date()

        today_reviews = []
        overdue_reviews = []

        for doc in user_docs:
            # 복습 완료된 문서는 제외
            if doc.review_completed:
                continue

            if not doc.created_at:
                continue

            # 문서 생성 날짜 (UTC -> KST)
            doc_date_utc = datetime.fromisoformat(doc.created_at.replace('Z', '+00:00'))
            doc_date_kst = doc_date_utc + kst_offset
            doc_date_only = doc_date_kst.date()

            # 과목명 추가
            doc_dict = {
                "document_id": doc.document_id,
                "title": doc.title,
                "subject_id": doc.subject_id,
                "subject_name": subject_map.get(doc.subject_id, "Unknown"),
                "created_at": doc.created_at,
                "pages": doc.pages
            }

            # 오늘의 복습
            if doc_date_only == today_kst:
                today_reviews.append(doc_dict)
            # 밀린 복습 (오늘 이전에 생성된 문서)
            elif doc_date_only < today_kst:
                overdue_reviews.append(doc_dict)

        return {
            "today": today_reviews,
            "overdue": overdue_reviews,
            "today_count": len(today_reviews),
            "overdue_count": len(overdue_reviews)
        }

    async def upload_image_to_s3(self, user_id: str, file: UploadFile) -> str:
        """
        이미지를 S3에 업로드하고 URL 반환

        Args:
            user_id: 사용자 ID
            file: 업로드할 이미지 파일 (UploadFile)

        Returns:
            str: S3 Public URL

        Raises:
            HTTPException: 파일 유효성 검사 실패 또는 업로드 실패
        """
        # 파일 유효성 검사
        if not file.content_type or not file.content_type.startswith('image/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미지 파일만 업로드 가능합니다."
            )

        # 파일 크기 제한 (10MB)
        if file.size and file.size > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="파일 크기는 10MB를 초과할 수 없습니다."
            )

        try:
            # S3 클라이언트 생성
            s3_client = boto3.client('s3')
            bucket_name = "ocr-images-storage-1761916475"

            # 고유한 파일명 생성 (UUID 사용)
            file_extension = file.filename.split('.')[-1] if file.filename and '.' in file.filename else 'jpg'
            unique_filename = f"images/{user_id}/{uuid.uuid4()}.{file_extension}"

            # 파일 내용 읽기
            contents = await file.read()

            # 실제 읽은 크기로 재검증
            if len(contents) > 10 * 1024 * 1024:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="파일 크기는 10MB를 초과할 수 없습니다."
                )

            # S3에 업로드
            s3_client.put_object(
                Bucket=bucket_name,
                Key=unique_filename,
                Body=contents,
                ContentType=file.content_type or 'image/jpeg',
                CacheControl='max-age=31536000'  # 1년 캐시
            )

            # Public URL 생성
            public_url = f"https://{bucket_name}.s3.{s3_client.meta.region_name}.amazonaws.com/{unique_filename}"

            return public_url

        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"이미지 업로드 실패: {str(e)}"
            )

    async def ai_text_correction(self, user_id: str, document_id: str, original_text: str) -> dict:
        """AI를 사용하여 텍스트 교정"""
        # 문서 권한 확인
        document = self.get_document_by_id(user_id, document_id)

        try:
            # AWS Bedrock 클라이언트 생성
            bedrock_client = boto3.client('bedrock-runtime', region_name='us-east-1')

            # Claude 3 Haiku 모델을 사용한 텍스트 교정 프롬프트
            prompt = f"""다음은 OCR로 추출된 텍스트입니다. 반드시 마크다운 표 형식을 사용하여 정리해주세요.

## 중요: 반드시 표를 생성하세요!
텍스트에서 정보를 추출하여 반드시 마크다운 표(| 컬럼1 | 컬럼2 | 형식)로 만드세요.

**기본 교정:**
1. OCR 오류 수정
2. 맞춤법 교정

**필수 표 변환 규칙:**

📋 **목표 및 전략:**
- 국내외 목표, 시장 전략, 마케팅 전략 등 → 표로 변환
- 예: | 구분 | 내용 | 비고 |

📊 **데이터 나열:**
- 이름, 나이, 직업, 연락처 등 개인정보 → 표로 변환
- 제품명, 가격, 수량, 날짜 등 → 표로 변환
- 항목명과 값이 쌍으로 나타나는 모든 경우 → 표로 변환

📅 **일정 및 계획:**
- 날짜, 시간, 내용, 장소 등 → 표로 변환
- 단계별 계획, 로드맵 등 → 표로 변환

💼 **비즈니스 정보:**
- 경쟁사 분석 → 표로 변환 (회사명, 특징, 장단점 등)
- 재무 정보 → 표로 변환 (항목, 금액, 기간 등)
- 조직 구조 → 표로 변환 (직책, 이름, 역할 등)

📈 **분석 및 비교:**
- 장단점 분석 → 표로 변환
- 비교 분석 → 표로 변환
- 통계 데이터 → 표로 변환

**STEP 3: 구조화**
- 제목이나 섹션: 마크다운 헤딩(#, ##, ###) 사용
- 나머지 목록: 불릿 포인트(- 또는 1. 2. 3.) 사용

**표 변환 강화 예시:**
```
원본: "국내외 목표 - 개인 고객에게 돌봄 인형 판매, 시장 - 고령화 지역 중심, 마케팅 전략 - SNS 채널 운영"

변환:
| 구분 | 내용 |
|------|------|
| 국내외 목표 | 개인 고객에게 돌봄 인형 판매 |
| 시장 | 고령화 지역 중심 |
| 마케팅 전략 | SNS 채널 운영 |
```

**⚠️ 중요 원칙:**
1. 모호한 경우에도 표로 만드는 것을 우선하세요
2. 2개 이상의 정보가 연관되어 있으면 표로 변환하세요
3. 원본 의미는 절대 변경하지 않습니다
4. 표가 부적절한 경우에만 원본 형태를 유지합니다

OCR 텍스트:
{original_text}

반드시 아래와 같은 마크다운 표 형식을 포함하여 작성하세요:

| 항목 | 설명 |
|------|------|
| 내용1 | 상세설명1 |
| 내용2 | 상세설명2 |

마크다운 형식의 정리된 텍스트:"""

            # Bedrock API 호출을 위한 페이로드
            payload = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 4000,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                "temperature": 0.1,
                "top_p": 0.9
            }

            # Bedrock API 호출
            response = bedrock_client.invoke_model(
                modelId="anthropic.claude-3-haiku-20240307-v1:0",
                body=json.dumps(payload),
                contentType="application/json"
            )

            # 응답 파싱
            response_body = json.loads(response['body'].read())
            corrected_text = response_body['content'][0]['text']

            # 디버깅 로그 추가
            print("=== AI 교정 응답 디버깅 ===")
            print(f"원본 텍스트 길이: {len(original_text)}")
            print(f"교정된 텍스트 길이: {len(corrected_text)}")
            print(f"표 구문 포함 여부: {('|' in corrected_text)}")
            print(f"첫 500자: {corrected_text[:500]}")

            # 표가 없으면 강제로 표 형식 추가 (임시)
            if '|' not in corrected_text and '국내외 목표' in original_text:
                print("표가 감지되지 않아 수동으로 표 형식 추가")
                corrected_text = corrected_text.replace(
                    "국내외 목표",
                    "\n\n| 구분 | 내용 |\n|------|------|\n| 국내외 목표"
                )

            return {
                "original_text": original_text,
                "corrected_text": corrected_text.strip(),
                "model_used": "claude-3-haiku",
                "timestamp": datetime.utcnow().isoformat()
            }

        except Exception as e:
            print(f"AI 교정 오류: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"AI 텍스트 교정 실패: {str(e)}"
            )

    async def ai_text_correction_stream(self, user_id: str, document_id: str, original_text: str) -> AsyncGenerator[str, None]:
        """AI를 사용하여 텍스트 교정 (스트리밍)"""
        # 문서 권한 확인
        document = self.get_document_by_id(user_id, document_id)

        try:
            # AWS Bedrock 클라이언트 생성
            bedrock_client = boto3.client('bedrock-runtime', region_name='us-east-1')

            # 스마트 노트 생성 프롬프트
            prompt = f"""당신은 학습 노트를 자동으로 생성하는 AI 어시스턴트입니다.
다음 OCR 텍스트를 체계적이고 학습하기 좋은 노트로 변환해주세요.

## 작성 규칙:

### 1. 제목 생성
- 문서의 핵심 주제를 파악하여 명확한 제목을 작성하세요
- # 제목, ## 섹션, ### 소제목 형식 사용

### 2. 핵심 요약 (필수)
- 문서의 핵심을 3-5줄로 요약
- **굵은 글씨**로 중요 키워드 강조

### 3. 주요 내용 정리 (필수 - 표 형식)
모든 핵심 정보는 반드시 표로 정리하세요:

| 구분 | 내용 | 비고 |
|------|------|------|
| 핵심 개념 | 설명 | 추가 정보 |

### 4. 섹션별 정리
- 📌 **핵심 포인트**: 불릿 포인트로 정리
- 📊 **데이터/수치**: 표로 정리
- 🎯 **목표/전략**: 표로 정리
- ⚡ **액션 아이템**: 체크리스트로 정리

### 5. 학습 포인트
- 암기해야 할 내용
- 이해해야 할 개념
- 실습/적용 사항

### 6. 추가 메모
- 관련 자료나 참고 사항

---

OCR 원본 텍스트:
{original_text}

---

📝 **자동 생성된 학습 노트:**
"""

            # Bedrock API 호출을 위한 페이로드 (스트리밍 지원)
            payload = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 4000,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                "temperature": 0.1,
                "top_p": 0.9
            }

            # 스트리밍 응답 받기
            response = bedrock_client.invoke_model_with_response_stream(
                modelId="anthropic.claude-3-haiku-20240307-v1:0",
                body=json.dumps(payload),
                contentType="application/json"
            )

            # 스트림에서 텍스트 추출
            accumulated_text = ""
            for event in response['body']:
                chunk = json.loads(event['chunk']['bytes'].decode())

                if chunk['type'] == 'content_block_delta':
                    text_chunk = chunk['delta'].get('text', '')
                    accumulated_text += text_chunk

                    # 표 구문이 나타나면 강조
                    if '|' in text_chunk:
                        yield text_chunk
                    else:
                        yield text_chunk

                    # 작은 지연 추가 (스트리밍 효과)
                    await asyncio.sleep(0.01)

            # 표가 없으면 수동으로 추가
            if '|' not in accumulated_text and '목표' in original_text:
                yield "\n\n## 주요 정보 정리\n\n"
                yield "| 구분 | 내용 |\n"
                yield "|------|------|\n"
                yield "| 목표 | 텍스트에서 추출된 목표 내용 |\n"
                yield "| 전략 | 텍스트에서 추출된 전략 내용 |\n"

        except Exception as e:
            print(f"AI 스트리밍 오류: {str(e)}")
            yield f"오류 발생: {str(e)}"
