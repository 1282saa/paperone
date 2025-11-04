# 이미지 업로드 문제 해결 가이드

## 📋 목차
1. [문제 개요](#문제-개요)
2. [근본 원인](#근본-원인)
3. [해결 과정](#해결-과정)
4. [최종 솔루션](#최종-솔루션)
5. [기술적 세부사항](#기술적-세부사항)
6. [학습 포인트](#학습-포인트)

---

## 🔴 문제 개요

### 증상
- 사용자가 이미지를 업로드하고 OCR 텍스트 추출 후 문서를 저장
- S3에 이미지 업로드는 성공하지만, **문서를 다시 열면 이미지가 로드 실패**
- 브라우저에서 깨진 이미지 아이콘만 표시됨

### 환경
- **프론트엔드**: React + Vite, CloudFront + S3
- **백엔드**: FastAPI + AWS Lambda, API Gateway
- **스토리지**: AWS S3 (public bucket)
- **이미지 처리**: Canvas API로 압축 (JPEG, 0.7 품질, 1024px)

---

## 🔍 근본 원인

### 핵심 문제: API Gateway의 바이너리 데이터 처리 실패

**프론트엔드에서 전송한 정상 JPEG 바이트**:
```
ffd8ffe000104a464946000101000001...
```

**백엔드(Lambda)에서 받은 손상된 바이트**:
```
efbfbdefbfbdefbfbdefbfbd00104a46...
```

### 왜 손상되었는가?

1. **API Gateway의 기본 동작**
   - API Gateway는 기본적으로 모든 요청 본문을 **텍스트(UTF-8)**로 처리
   - `multipart/form-data`도 예외가 아님

2. **바이너리 데이터의 텍스트 변환 시도**
   - JPEG의 바이너리 바이트(예: `0xFF`, `0xD8`)가 UTF-8로 해석 불가능
   - 이런 바이트들이 **UTF-8 Replacement Character** (`U+FFFD` = `efbfbd`)로 치환됨

3. **복구 불가능한 손상**
   - 한번 `efbfbd`로 변환되면 원본 바이트 복구 불가능
   - S3에 손상된 파일이 저장됨

### 오해했던 부분들

❌ **처음 의심했던 것들**:
- S3 버킷이 private이라서 → 실제로는 public이었음
- FastAPI의 `UploadFile` 파일 포인터 문제 → 관련 없었음
- 프론트엔드 Canvas의 `toBlob()` 문제 → 실제로는 정상 동작
- Blob을 File로 변환할 때 문제 → 관련 없었음

✅ **실제 원인**:
- **API Gateway가 바이너리 미디어 타입을 인식하지 못함**

---

## 🛠️ 해결 과정

### 1단계: 문제 위치 파악 (디버깅)

#### 프론트엔드 디버깅 추가
**파일**: `frontend/src/services/subjectsApi.js`

```javascript
export const uploadImageToS3 = async (file) => {
  console.log("=== uploadImageToS3 디버깅 ===");

  // Blob의 첫 16바이트 확인
  const arrayBuffer = await file.slice(0, 16).arrayBuffer();
  const bytes = new Uint8Array(arrayBuffer);
  const hexString = Array.from(bytes)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  console.log("첫 16바이트 (hex):", hexString);

  if (!hexString.startsWith('ffd8')) {
    console.error("❌ JPEG 매직 넘버 없음");
  } else {
    console.log("✅ JPEG 매직 넘버 확인됨 (프론트엔드)");
  }
  // ...
};
```

**결과**: 프론트엔드에서는 `ffd8ffe0...` (정상 JPEG) ✅

#### 백엔드 디버깅 추가
**파일**: `backend/src/domains/subjects/service.py`

```python
async def upload_image_to_s3(self, user_id: str, file: UploadFile) -> str:
    print(f"=== S3 업로드 디버깅 시작 ===")
    print(f"파일명: {file.filename}")
    print(f"Content-Type: {file.content_type}")

    contents = await file.read()
    print(f"읽은 바이트 수: {len(contents)}")
    print(f"첫 16바이트 (hex): {contents[:16].hex()}")

    # JPEG 매직 넘버 확인
    if contents[:2].hex() != 'ffd8':
        print(f"⚠️ 경고: JPEG 매직 넘버가 아닙니다! 실제: {contents[:2].hex()}")
    else:
        print(f"✅ JPEG 매직 넘버 확인됨")
    # ...
```

**결과**: 백엔드에서는 `efbfbdefbfbd...` (손상됨) ❌

**결론**: **전송 과정에서 손상** → API Gateway 문제!

### 2단계: 시도했던 해결책들 (실패)

#### 시도 1: S3 버킷 Public Access 설정
```bash
# Public Access Block 비활성화
aws s3api put-public-access-block \
  --bucket ocr-images-storage-1761916475 \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Bucket Policy 설정
aws s3api put-bucket-policy \
  --bucket ocr-images-storage-1761916475 \
  --policy '{...}'
```
**결과**: 업로드는 성공하지만 여전히 이미지 손상 ❌

#### 시도 2: FastAPI 파일 읽기 방식 변경
```python
# BytesIO 버퍼 사용
import io
contents = await file.read()
file_buffer = io.BytesIO(contents)
file_buffer.seek(0)
s3_client.upload_fileobj(file_buffer, bucket, key)
```
**결과**: 변화 없음 ❌

#### 시도 3: S3 업로드 방식 변경 (upload_fileobj → put_object)
```python
# 직접 바이트 전달
s3_client.put_object(
    Bucket=bucket_name,
    Key=unique_filename,
    Body=contents,  # bytes 직접 전달
    ContentType=file.content_type
)
```
**결과**: 변화 없음 ❌

#### 시도 4: 프론트엔드 Blob → File 변환
```javascript
if (file instanceof Blob && !(file instanceof File)) {
  const filename = 'compressed_image.jpg';
  file = new File([file], filename, { type: 'image/jpeg' });
}
```
**결과**: 변화 없음 ❌

### 3단계: 최종 해결책 (성공) ✅

#### API Gateway Binary Media Types 설정
**파일**: `backend/serverless.yml`

```yaml
provider:
  name: aws
  runtime: python3.11

  # 핵심 설정 추가!
  apiGateway:
    binaryMediaTypes:
      - 'multipart/form-data'
      - 'image/jpeg'
      - 'image/png'
      - 'image/jpg'
      - 'image/*'
```

**배포**:
```bash
cd backend
serverless deploy
```

**결과**:
- 프론트엔드: `ffd8ffe0...` ✅
- 백엔드: `ffd8ffe0...` ✅ (더 이상 손상되지 않음!)
- S3 이미지: 정상 로드 ✅

---

## ✅ 최종 솔루션

### 변경된 파일들

#### 1. `backend/serverless.yml`
```yaml
provider:
  apiGateway:
    binaryMediaTypes:
      - 'multipart/form-data'  # 필수!
      - 'image/*'               # 모든 이미지 타입
```

#### 2. `backend/src/domains/subjects/service.py`
```python
async def upload_image_to_s3(self, user_id: str, file: UploadFile) -> str:
    # 파일 내용 읽기
    contents = await file.read()

    # S3에 직접 업로드 (put_object 사용)
    s3_client.put_object(
        Bucket=bucket_name,
        Key=unique_filename,
        Body=contents,  # bytes
        ContentType=file.content_type or 'image/jpeg',
        CacheControl='max-age=31536000'
    )

    # Public URL 반환
    return f"https://{bucket_name}.s3.{region}.amazonaws.com/{unique_filename}"
```

#### 3. `frontend/src/services/subjectsApi.js`
```javascript
export const uploadImageToS3 = async (file) => {
  const formData = new FormData();

  // Blob을 File 객체로 변환 (filename 보장)
  if (file instanceof Blob && !(file instanceof File)) {
    file = new File([file], 'compressed_image.jpg', {
      type: file.type || 'image/jpeg'
    });
  }

  formData.append('file', file);

  return apiRequest(`${API_ENDPOINTS.subjects}/upload-image`, {
    method: 'POST',
    body: formData,
  });
};
```

---

## 🔬 기술적 세부사항

### API Gateway Binary Media Types란?

#### 동작 원리

1. **설정 전 (기본 동작)**:
   ```
   Browser → API Gateway (텍스트로 해석) → Lambda (손상된 데이터)
   ```
   - 모든 요청을 UTF-8 텍스트로 처리
   - 바이너리 바이트를 텍스트 변환 시도 → `efbfbd`로 치환

2. **설정 후**:
   ```
   Browser → API Gateway (Base64 인코딩) → Lambda (자동 디코딩) → 정상 바이너리
   ```
   - Content-Type이 `binaryMediaTypes` 목록에 있으면
   - 요청 본문을 **Base64로 인코딩**하여 Lambda에 전달
   - Lambda(FastAPI)가 자동으로 Base64 디코딩
   - 원본 바이너리 데이터 복원 ✅

#### 설정 가능한 값들

```yaml
apiGateway:
  binaryMediaTypes:
    - '*/*'                    # 모든 타입 (권장하지 않음)
    - 'multipart/form-data'    # FormData 업로드
    - 'image/*'                # 모든 이미지
    - 'image/jpeg'             # JPEG만
    - 'image/png'              # PNG만
    - 'application/pdf'        # PDF 파일
    - 'application/octet-stream'  # 바이너리 스트림
```

### JPEG 파일 구조

#### 매직 넘버 (Magic Number)
```
FF D8 FF E0 00 10 4A 46 49 46 00 01 01 00 00 01
│  │  │  │  │     │  │  │  │  │
│  │  │  │  │     └──┴──┴──┴──┴─ "JFIF" (ASCII)
│  │  │  │  └─ 길이 (16바이트)
│  │  │  └─ JFIF APP0 마커
│  │  └─ Start of Image 마커
│  └─ JPEG 시작
└─ SOI (Start Of Image)
```

- 모든 JPEG 파일은 **반드시** `FF D8`로 시작
- 이어서 `FF E0` (JFIF APP0 마커)
- 이를 검증하여 파일 손상 여부 확인 가능

#### 손상된 파일 예시
```
EF BF BD EF BF BD EF BF BD EF BF BD 00 10 4A 46
│                                      │     │  │
└─ UTF-8 Replacement Character         │     └──┴─ "JF" (일부만 남음)
   (원본 바이트를 UTF-8로 해석 실패)   └─ 일부 바이트는 살아남음
```

### Canvas API 이미지 압축

#### 압축 로직
```javascript
const compressImage = (file, quality = 0.7, maxWidth = 1024) => {
  return new Promise((resolve, reject) => {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const img = new Image();

    img.onload = () => {
      // 비율 유지하면서 리사이즈
      const ratio = Math.min(maxWidth / img.width, maxWidth / img.height);
      canvas.width = Math.floor(img.width * ratio);
      canvas.height = Math.floor(img.height * ratio);

      // 캔버스에 그리기
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

      // JPEG Blob으로 변환
      canvas.toBlob((blob) => {
        resolve(blob);
      }, 'image/jpeg', quality);  // 70% 품질
    };

    img.src = URL.createObjectURL(file);
  });
};
```

**효과**:
- 원본 PNG (5MB) → 압축 JPEG (200KB)
- 업로드 속도 향상
- S3 스토리지 비용 절감

---

## 💡 학습 포인트

### 1. 서버리스 환경에서의 바이너리 데이터 처리

#### API Gateway의 특성
- **HTTP API vs REST API**:
  - HTTP API: 자동으로 바이너리 처리 (별도 설정 불필요)
  - REST API: `binaryMediaTypes` 설정 필수 ⚠️

- **Lambda 프록시 통합**:
  - API Gateway → Lambda 전달 시 요청 본문 변환
  - Base64 인코딩/디코딩 자동 처리

#### 주의사항
```yaml
# ❌ 잘못된 설정
apiGateway:
  binaryMediaTypes:
    - 'image/jpeg'
    # multipart/form-data 빠짐! ← FormData는 이 타입으로 전송됨
```

```yaml
# ✅ 올바른 설정
apiGateway:
  binaryMediaTypes:
    - 'multipart/form-data'  # 필수!
    - 'image/*'              # 추가 보호
```

### 2. 디버깅 전략

#### 바이너리 데이터 디버깅 순서

1. **프론트엔드에서 검증**
   ```javascript
   const bytes = new Uint8Array(await file.slice(0, 16).arrayBuffer());
   console.log(Array.from(bytes).map(b => b.toString(16)).join(''));
   ```

2. **백엔드에서 검증**
   ```python
   contents = await file.read()
   print(f"첫 16바이트: {contents[:16].hex()}")
   ```

3. **S3에서 검증**
   ```bash
   curl -s "S3_URL" | xxd | head -2
   ```

4. **비교 분석**
   - 프론트 OK, 백엔드 손상 → **전송 문제** (API Gateway)
   - 프론트 손상, 백엔드 손상 → **생성 문제** (Canvas/압축)
   - 백엔드 OK, S3 손상 → **저장 문제** (S3 업로드)

### 3. AWS 서비스 통합 시 체크리스트

#### S3 Public Access
```bash
# 1. Public Access Block 확인
aws s3api get-public-access-block --bucket BUCKET_NAME

# 2. Bucket Policy 확인
aws s3api get-bucket-policy --bucket BUCKET_NAME

# 3. Object ACL 확인 (BucketOwnerEnforced인 경우 ACL 사용 불가)
aws s3api get-bucket-ownership-controls --bucket BUCKET_NAME
```

#### API Gateway 설정
```bash
# Binary Media Types 확인
aws apigateway get-rest-api --rest-api-id API_ID

# Stage 설정 확인
aws apigateway get-stage \
  --rest-api-id API_ID \
  --stage-name STAGE
```

#### Lambda 권한
```yaml
# serverless.yml
iamRoleStatements:
  - Effect: Allow
    Action:
      - s3:PutObject      # 업로드
      - s3:GetObject      # 다운로드
      - s3:DeleteObject   # 삭제
    Resource: 'arn:aws:s3:::BUCKET_NAME/*'
```

### 4. 성능 최적화

#### 이미지 압축 전략
```javascript
// 용도별 압축 설정
const compressionConfigs = {
  thumbnail: { quality: 0.5, maxWidth: 300 },   // 썸네일
  preview: { quality: 0.7, maxWidth: 1024 },    // 미리보기
  original: { quality: 0.9, maxWidth: 2048 },   // 원본 보관
};
```

#### S3 최적화
```python
# CloudFront와 함께 사용 시
s3_client.put_object(
    CacheControl='max-age=31536000',  # 1년 캐시
    ContentType='image/jpeg',
    Metadata={
        'original-filename': original_name,
        'uploaded-by': user_id,
    }
)
```

---

## 🚀 향후 개선사항

### 1. 이미지 포맷 자동 감지
```python
import imghdr

async def upload_image_to_s3(self, user_id: str, file: UploadFile) -> str:
    contents = await file.read()

    # 실제 이미지 타입 감지
    detected_type = imghdr.what(None, h=contents[:32])

    if detected_type not in ['jpeg', 'png', 'gif']:
        raise HTTPException(400, "지원하지 않는 이미지 형식")

    # Content-Type 보정
    content_type = f"image/{detected_type}"
```

### 2. 썸네일 자동 생성
```python
from PIL import Image
import io

def create_thumbnail(image_bytes, size=(300, 300)):
    img = Image.open(io.BytesIO(image_bytes))
    img.thumbnail(size, Image.Resampling.LANCZOS)

    buffer = io.BytesIO()
    img.save(buffer, format='JPEG', quality=70)
    return buffer.getvalue()

# S3에 원본 + 썸네일 저장
s3_client.put_object(Bucket=bucket, Key=f"{key}.jpg", Body=contents)
s3_client.put_object(Bucket=bucket, Key=f"{key}_thumb.jpg",
                     Body=create_thumbnail(contents))
```

### 3. 에러 핸들링 강화
```javascript
export const uploadImageToS3 = async (file, retries = 3) => {
  for (let i = 0; i < retries; i++) {
    try {
      const result = await apiRequest(...);

      // 업로드 성공 후 검증
      const response = await fetch(result.image_url, { method: 'HEAD' });
      if (response.ok) {
        return result;
      }

      throw new Error('이미지 검증 실패');
    } catch (error) {
      if (i === retries - 1) throw error;

      // 지수 백오프
      await new Promise(r => setTimeout(r, Math.pow(2, i) * 1000));
    }
  }
};
```

### 4. CloudFront CDN 통합
```yaml
# serverless.yml
resources:
  Resources:
    CloudFrontDistribution:
      Type: AWS::CloudFront::Distribution
      Properties:
        DistributionConfig:
          Origins:
            - Id: S3Origin
              DomainName: ${self:custom.imageBucket}.s3.amazonaws.com
              S3OriginConfig:
                OriginAccessIdentity: ''
          DefaultCacheBehavior:
            TargetOriginId: S3Origin
            ViewerProtocolPolicy: redirect-to-https
            CachePolicyId: 658327ea-f89d-4fab-a63d-7e88639e58f6  # CachingOptimized
```

---

## 📚 참고 자료

### AWS 공식 문서
- [API Gateway Binary Media Types](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-payload-encodings.html)
- [Lambda Proxy Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html)
- [S3 Public Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)

### 관련 기술
- [JPEG File Format](https://www.w3.org/Graphics/JPEG/itu-t81.pdf)
- [Canvas API - toBlob()](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/toBlob)
- [FastAPI File Upload](https://fastapi.tiangolo.com/tutorial/request-files/)

### 유사 문제 해결 사례
- [Stack Overflow: API Gateway Binary Data](https://stackoverflow.com/questions/40347426)
- [GitHub Issue: Serverless Framework Binary](https://github.com/serverless/serverless/issues/3366)

---

## ✍️ 작성 정보

- **작성일**: 2025-11-04
- **문제 발생일**: 2025-11-04
- **해결일**: 2025-11-04
- **총 소요 시간**: 약 3시간
- **시도한 해결책 수**: 6개
- **최종 해결책**: API Gateway Binary Media Types 설정

---

## 🎯 요약

**문제**: 이미지 업로드 후 S3에서 다시 불러올 때 손상된 파일 로드

**원인**: API Gateway가 바이너리 데이터를 텍스트로 잘못 해석

**해결**: `serverless.yml`에 `binaryMediaTypes: ['multipart/form-data']` 추가

**핵심 교훈**:
- AWS Lambda + API Gateway 환경에서는 바이너리 미디어 타입 설정 필수
- 디버깅 시 전송 체인의 각 단계별로 바이트 검증 필요
- 바이너리 데이터는 Base64 인코딩 없이 직접 전송 불가능
