# S3 이미지 업로드 가이드 (백엔드)

## 📁 관련 파일

### 1. `serverless.yml`
**중요 설정**: API Gateway Binary Media Types

```yaml
provider:
  apiGateway:
    binaryMediaTypes:
      - 'multipart/form-data'  # FormData 업로드 필수!
      - 'image/*'              # 모든 이미지 타입
```

**왜 필요한가?**
- API Gateway는 기본적으로 모든 요청을 텍스트(UTF-8)로 처리
- 바이너리 데이터(이미지)를 텍스트로 변환하면 손상됨
- `binaryMediaTypes` 설정 시 Base64로 인코딩하여 안전하게 전달

**주의사항**:
- ⚠️ 이 설정 없이는 이미지가 손상되어 업로드됨!
- ⚠️ `multipart/form-data`를 꼭 포함해야 함 (FormData 전송 시)

---

### 2. `src/domains/subjects/router.py`
**엔드포인트**: `POST /api/v1/subjects/upload-image`

```python
@router.post("/upload-image")
async def upload_image(
    current_user: CurrentUser,
    file: UploadFile = File(...),
):
    """이미지를 S3에 업로드하고 URL 반환"""
    service = DocumentService()
    image_url = await service.upload_image_to_s3(current_user.id, file)
    return {"image_url": image_url}
```

**요청 형식**:
```
POST /api/v1/subjects/upload-image
Content-Type: multipart/form-data
Authorization: Bearer {token}

Body:
  file: (binary)
```

**응답 형식**:
```json
{
  "image_url": "https://ocr-images-storage-1761916475.s3.us-east-1.amazonaws.com/images/user-123/abc-123.jpg"
}
```

---

### 3. `src/domains/subjects/service.py`
**함수**: `DocumentService.upload_image_to_s3()`

```python
async def upload_image_to_s3(self, user_id: str, file: UploadFile) -> str:
    """이미지를 S3에 업로드하고 URL 반환"""

    # 1. 파일 유효성 검사
    if not file.content_type.startswith('image/'):
        raise HTTPException(400, "이미지 파일만 업로드 가능")

    # 2. 파일 크기 검사 (10MB)
    if file.size > 10 * 1024 * 1024:
        raise HTTPException(400, "파일 크기 10MB 초과")

    # 3. 파일 읽기
    contents = await file.read()

    # 4. JPEG 매직 넘버 검증 (디버깅)
    if contents[:2].hex() != 'ffd8':
        print(f"⚠️ JPEG 매직 넘버 없음: {contents[:2].hex()}")

    # 5. S3 업로드
    s3_client.put_object(
        Bucket=bucket_name,
        Key=unique_filename,
        Body=contents,  # bytes 직접 전달
        ContentType=file.content_type,
        CacheControl='max-age=31536000'  # 1년 캐시
    )

    # 6. Public URL 반환
    return f"https://{bucket_name}.s3.{region}.amazonaws.com/{unique_filename}"
```

**디버깅 로그**:
```
=== S3 업로드 디버깅 시작 ===
파일명: compressed_image.jpg
Content-Type: image/jpeg
확장자: jpg
S3 키: images/test-user-001/40ed55aa-fb90-412b-b96b-ecae95fb1913.jpg
읽은 바이트 수: 96656
첫 16바이트 (hex): ffd8ffe000104a464946000101000001
✅ JPEG 매직 넘버 확인됨
✅ S3 업로드 성공
```

---

## 🔧 로컬 개발

### 환경 변수
`.env` 파일:
```bash
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
```

### 로컬 실행
```bash
# 가상환경 활성화
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
uvicorn src.main:app --reload
```

### 배포
```bash
# serverless 배포
serverless deploy

# 로그 확인
serverless logs -f api --tail
```

---

## 🐛 트러블슈팅

### 문제: 이미지가 손상되어 업로드됨

**증상**:
```
첫 16바이트 (hex): efbfbdefbfbdefbfbdefbfbd00104a46
⚠️ 경고: JPEG 매직 넘버가 아닙니다! 실제: efbf
```

**해결**:
1. `serverless.yml`에 `binaryMediaTypes` 설정 확인
2. 설정 추가 후 재배포: `serverless deploy`

### 문제: S3 업로드 권한 오류

**증상**:
```
ClientError: An error occurred (AccessDenied) when calling the PutObject operation
```

**해결**:
`serverless.yml`의 IAM 권한 확인:
```yaml
iamRoleStatements:
  - Effect: Allow
    Action:
      - s3:PutObject
      - s3:GetObject
    Resource: 'arn:aws:s3:::ocr-images-storage-1761916475/*'
```

### 문제: FastAPI에서 파일을 못 읽음

**증상**:
```
파일 크기: None
첫 16바이트 (hex): (빈 값)
```

**해결**:
1. Content-Type이 `multipart/form-data`인지 확인
2. FormData에 파일이 제대로 추가되었는지 확인
3. API Gateway 설정 확인

---

## 📊 성능 고려사항

### 파일 크기 제한
- **현재**: 10MB
- **API Gateway 제한**: 10MB (페이로드)
- **Lambda 제한**: 6MB (동기 호출), 250KB (비동기)

### 대용량 파일 업로드
10MB 이상의 파일은 **Presigned URL** 방식 사용:

```python
def generate_presigned_url(user_id: str, filename: str) -> dict:
    """S3 Presigned URL 생성 (클라이언트가 직접 업로드)"""
    s3_client = boto3.client('s3')

    key = f"images/{user_id}/{uuid.uuid4()}.{filename.split('.')[-1]}"

    presigned_url = s3_client.generate_presigned_url(
        'put_object',
        Params={
            'Bucket': bucket_name,
            'Key': key,
            'ContentType': 'image/jpeg',
        },
        ExpiresIn=3600  # 1시간
    )

    return {
        'upload_url': presigned_url,
        'image_url': f"https://{bucket_name}.s3.amazonaws.com/{key}"
    }
```

---

## 🔐 보안

### 현재 설정
- ✅ S3 버킷: Public Read (버킷 정책)
- ✅ 업로드: 인증된 사용자만 (JWT 토큰)
- ✅ 파일명: UUID로 랜덤 생성 (추측 불가)
- ✅ Content-Type 검증
- ✅ 파일 크기 제한

### 개선 권장사항
1. **CloudFront CDN** 사용
   - S3를 Private으로 변경
   - OAI(Origin Access Identity)로 CloudFront만 접근 허용

2. **이미지 스캔**
   - 악성 코드 검사 (ClamAV 등)
   - 메타데이터 제거 (EXIF)

3. **Rate Limiting**
   - API Gateway 요청 제한
   - 사용자당 업로드 횟수 제한

---

## 📝 체크리스트

배포 전 확인사항:

- [ ] `serverless.yml`에 `binaryMediaTypes` 설정됨
- [ ] S3 버킷 생성 및 정책 설정됨
- [ ] IAM 권한 설정됨 (`s3:PutObject`)
- [ ] 환경 변수 설정됨
- [ ] 로컬에서 테스트 완료
- [ ] 디버깅 로그 추가됨
- [ ] 파일 크기 제한 적용됨
- [ ] Content-Type 검증 적용됨

---

상세한 트러블슈팅은 `/web_project/IMAGE_UPLOAD_TROUBLESHOOTING.md` 참고
