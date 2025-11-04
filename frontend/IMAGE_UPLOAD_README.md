# 이미지 업로드 가이드 (프론트엔드)

## 📁 관련 파일

### 1. `src/services/subjectsApi.js`
**함수**: `uploadImageToS3()`

이미지를 S3에 업로드하는 API 호출 함수입니다.

```javascript
/**
 * 이미지를 S3에 업로드
 * @param {Blob|File} file - 업로드할 이미지 (Blob 또는 File)
 * @returns {Promise<{image_url: string}>}
 */
export const uploadImageToS3 = async (file) => {
  // 1. 디버깅: Blob 바이트 검증
  const arrayBuffer = await file.slice(0, 16).arrayBuffer();
  const bytes = new Uint8Array(arrayBuffer);
  const hexString = Array.from(bytes)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  console.log("첫 16바이트 (hex):", hexString);

  // JPEG 매직 넘버 검증 (ffd8로 시작해야 함)
  if (!hexString.startsWith('ffd8')) {
    console.error("❌ JPEG 매직 넘버 없음!");
  }

  // 2. Blob을 File 객체로 변환 (filename 보장)
  if (file instanceof Blob && !(file instanceof File)) {
    file = new File([file], 'compressed_image.jpg', {
      type: file.type || 'image/jpeg'
    });
  }

  // 3. FormData 생성
  const formData = new FormData();
  formData.append('file', file);

  // 4. API 호출
  return apiRequest(`${API_ENDPOINTS.subjects}/upload-image`, {
    method: 'POST',
    body: formData,
    // Content-Type은 브라우저가 자동으로 설정 (multipart/form-data)
  });
};
```

**주요 포인트**:
- ✅ Blob을 File 객체로 변환하여 filename 보장
- ✅ JPEG 매직 넘버 검증 (`ffd8`로 시작)
- ✅ FormData 사용 (자동으로 `multipart/form-data`)

---

### 2. `src/screens/Screen/sections/SubjectDetail/SubjectDetail.jsx`
**함수**: `compressImage()`

Canvas API를 사용하여 이미지를 압축합니다.

```javascript
/**
 * 이미지 압축
 * @param {File} file - 원본 이미지 파일
 * @param {number} quality - JPEG 품질 (0~1)
 * @param {number} maxWidth - 최대 너비 (px)
 * @returns {Promise<Blob>} 압축된 JPEG Blob
 */
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
        if (blob) {
          console.log("압축 완료:", {
            압축후크기: blob.size,
            압축률: ((file.size - blob.size) / file.size * 100).toFixed(1) + "%"
          });
          resolve(blob);
        } else {
          reject(new Error("Canvas to Blob 변환 실패"));
        }
      }, 'image/jpeg', quality);

      URL.revokeObjectURL(img.src);
    };

    img.onerror = () => reject(new Error("이미지 로드 실패"));
    img.src = URL.createObjectURL(file);
  });
};
```

**압축 설정**:
- `quality`: 0.7 (70% 품질)
- `maxWidth`: 1024px
- 출력 형식: JPEG

**효과**:
- 원본 PNG 5MB → 압축 JPEG 200KB
- 업로드 속도 10배 향상
- S3 스토리지 비용 절감

---

### 3. `src/screens/Screen/sections/SubjectDetail/SubjectDetail.jsx`
**함수**: `handleSaveText()`

OCR 결과를 저장하고 이미지를 S3에 업로드합니다.

```javascript
const handleSaveText = async () => {
  try {
    setIsProcessing(true);

    let imageUrl = null;

    if (uploadedImageFile) {
      // 1. 이미지 압축
      const compressedFile = await compressImage(
        uploadedImageFile,
        0.7,    // 70% 품질
        1024    // 최대 1024px
      );

      // 2. S3에 업로드
      try {
        const uploadResult = await uploadImageToS3(compressedFile);
        imageUrl = uploadResult.image_url;
        console.log("✅ S3 업로드 성공:", imageUrl);
      } catch (s3Error) {
        console.warn("S3 업로드 실패, base64로 폴백:", s3Error);

        // 폴백: base64로 저장
        const reader = new FileReader();
        imageUrl = await new Promise((resolve, reject) => {
          reader.onload = () => resolve(reader.result);
          reader.onerror = reject;
          reader.readAsDataURL(compressedFile);
        });
      }
    }

    // 3. 문서 저장
    const documentData = {
      subject_id: subjectId,
      title: editableText.split('\n')[0].substring(0, 50) || "새 문서",
      extracted_text: editableText,
      original_filename: uploadedImageFile?.name || "uploaded_image.jpg",
      file_size: uploadedImageFile?.size || 0,
      pages: 1,
    };

    if (imageUrl) {
      documentData.image_url = imageUrl;
    }

    const savedDocument = await createDocument(documentData);
    console.log("문서 저장 성공:", savedDocument);

    await loadDocuments();
    handleCloseOcrResultModal();

  } catch (error) {
    console.error("문서 저장 실패:", error);
    alert("문서 저장에 실패했습니다.");
  } finally {
    setIsProcessing(false);
  }
};
```

**플로우**:
1. 이미지 압축 (Canvas)
2. S3 업로드 (실패 시 base64 폴백)
3. 문서 데이터 생성
4. 백엔드에 저장
5. 문서 목록 새로고침

---

## 🔬 디버깅

### 브라우저 콘솔 로그

정상적인 업로드 시:
```
이미지 압축 시작: {파일명: "image.png", 원본크기: 5242880, 타입: "image/png"}
이미지 로드 완료: {원본가로: 1920, 원본세로: 1080}
압축 후 크기: {압축가로: 1024, 압축세로: 576, 압축비율: 0.533}
압축 완료: {압축후크기: 204800, 압축률: "96.1%"}

=== uploadImageToS3 디버깅 ===
입력 파일 타입: Blob
파일 크기: 204800
파일 타입: image/jpeg
첫 16바이트 (hex): ffd8ffe000104a464946000101000001
✅ JPEG 매직 넘버 확인됨 (프론트엔드)
Blob을 File 객체로 변환함: compressed_image.jpg

S3에 이미지 업로드 시도 중...
✅ S3 업로드 성공: https://ocr-images-storage-1761916475.s3.us-east-1.amazonaws.com/images/test-user-001/xxx.jpg
```

### 문제 발생 시

**증상 1**: Blob이 손상됨
```
첫 16바이트 (hex): efbfbdefbfbdefbfbd...
❌ 경고: JPEG 매직 넘버가 없습니다!
```
**원인**: Canvas `toBlob()` 실패 또는 브라우저 문제
**해결**: 다른 브라우저에서 테스트

**증상 2**: FormData 전송 실패
```
POST /api/v1/subjects/upload-image 400
이미지 파일만 업로드 가능합니다.
```
**원인**: Content-Type이 잘못 설정됨
**해결**: FormData 생성 코드 확인

**증상 3**: CORS 에러
```
Access to fetch at '...' has been blocked by CORS policy
```
**원인**: 백엔드 CORS 설정 문제
**해결**: `serverless.yml` CORS 설정 확인

---

## 🎨 지원하는 이미지 형식

### 입력 (원본)
- ✅ PNG
- ✅ JPEG/JPG
- ✅ GIF (애니메이션 제외)
- ✅ WebP
- ❌ SVG (지원 안 함)
- ❌ HEIC (변환 필요)

### 출력 (압축 후)
- 항상 **JPEG** 형식으로 변환
- 품질: 70%
- 최대 크기: 1024px

---

## 🚀 최적화 팁

### 1. 압축 품질 조정

```javascript
// 용도별 압축 설정
const compressionConfigs = {
  // 썸네일 (빠른 로딩)
  thumbnail: {
    quality: 0.5,
    maxWidth: 300,
  },

  // 미리보기 (기본)
  preview: {
    quality: 0.7,
    maxWidth: 1024,
  },

  // 고품질 (아카이빙)
  highQuality: {
    quality: 0.9,
    maxWidth: 2048,
  },
};

const config = compressionConfigs.preview;
const compressed = await compressImage(file, config.quality, config.maxWidth);
```

### 2. Progressive JPEG

```javascript
// Progressive JPEG는 Canvas API에서 직접 지원 안 함
// 백엔드에서 PIL(Pillow)로 변환 권장

// 백엔드 (Python):
from PIL import Image
img.save(buffer, format='JPEG', quality=70, progressive=True)
```

### 3. WebP 형식 지원

```javascript
// WebP 지원 브라우저 확인
const supportsWebP = document.createElement('canvas')
  .toDataURL('image/webp')
  .indexOf('data:image/webp') === 0;

canvas.toBlob((blob) => {
  resolve(blob);
}, supportsWebP ? 'image/webp' : 'image/jpeg', quality);
```

### 4. 이미지 리사이즈 전략

```javascript
// 큰 이미지는 더 작게 압축
const getMaxWidth = (originalWidth) => {
  if (originalWidth > 4000) return 1024;
  if (originalWidth > 2000) return 1536;
  if (originalWidth > 1000) return 2048;
  return originalWidth; // 작은 이미지는 그대로
};

const maxWidth = getMaxWidth(img.width);
const compressed = await compressImage(file, 0.7, maxWidth);
```

---

## 🔐 보안

### 파일 검증

```javascript
// 파일 크기 검증 (10MB)
const MAX_FILE_SIZE = 10 * 1024 * 1024;

if (file.size > MAX_FILE_SIZE) {
  alert('파일 크기는 10MB를 초과할 수 없습니다.');
  return;
}

// 파일 타입 검증
const ALLOWED_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];

if (!ALLOWED_TYPES.includes(file.type)) {
  alert('지원하지 않는 파일 형식입니다.');
  return;
}

// 실제 파일 내용 검증 (매직 넘버)
const buffer = await file.slice(0, 4).arrayBuffer();
const bytes = new Uint8Array(buffer);
const hex = Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');

const validHeaders = {
  'ffd8ffe0': 'JPEG',
  'ffd8ffe1': 'JPEG (EXIF)',
  '89504e47': 'PNG',
  '47494638': 'GIF',
};

if (!validHeaders[hex.slice(0, 8)]) {
  alert('손상된 이미지 파일입니다.');
  return;
}
```

### XSS 방지

```javascript
// 사용자가 업로드한 이미지를 HTML에 직접 삽입하지 않음
// S3 URL을 사용하여 이미지 로드

// ❌ 위험
<img src={uploadedImageFile} />

// ✅ 안전
<img src={s3ImageUrl} />
```

---

## 📊 성능 모니터링

### 업로드 시간 측정

```javascript
const uploadImageToS3 = async (file) => {
  const startTime = performance.now();

  try {
    const result = await apiRequest(...);

    const endTime = performance.now();
    const duration = ((endTime - startTime) / 1000).toFixed(2);

    console.log(`업로드 완료: ${duration}초, 크기: ${file.size / 1024}KB`);

    // 분석 전송 (Google Analytics 등)
    gtag('event', 'image_upload', {
      file_size: file.size,
      duration_seconds: duration,
      file_type: file.type,
    });

    return result;
  } catch (error) {
    // 에러 추적
    gtag('event', 'image_upload_error', {
      error_message: error.message,
    });
    throw error;
  }
};
```

### 압축 효율 추적

```javascript
const compressImage = async (file, quality, maxWidth) => {
  const originalSize = file.size;
  const blob = await /* ... */;

  const compressionRatio = ((originalSize - blob.size) / originalSize * 100);

  console.log(`압축 효율: ${compressionRatio.toFixed(1)}%`);
  console.log(`원본: ${(originalSize / 1024).toFixed(1)}KB → 압축: ${(blob.size / 1024).toFixed(1)}KB`);

  return blob;
};
```

---

## 🧪 테스트

### 단위 테스트 (Jest)

```javascript
import { uploadImageToS3 } from '../services/subjectsApi';

describe('uploadImageToS3', () => {
  it('should upload valid JPEG file', async () => {
    // JPEG Blob 생성
    const blob = new Blob([new Uint8Array([0xff, 0xd8, 0xff, 0xe0])], {
      type: 'image/jpeg'
    });

    const result = await uploadImageToS3(blob);

    expect(result.image_url).toContain('s3.amazonaws.com');
    expect(result.image_url).toContain('.jpg');
  });

  it('should reject non-image file', async () => {
    const blob = new Blob(['text'], { type: 'text/plain' });

    await expect(uploadImageToS3(blob)).rejects.toThrow();
  });
});
```

### E2E 테스트 (Cypress)

```javascript
describe('Image Upload', () => {
  it('uploads and displays image correctly', () => {
    cy.visit('/subject/123');

    // 파일 선택
    cy.get('input[type="file"]').attachFile('test-image.jpg');

    // OCR 결과 대기
    cy.contains('추출된 텍스트', { timeout: 10000 });

    // 저장
    cy.contains('저장하기').click();

    // 문서 상세 페이지
    cy.url().should('include', '/document/');

    // 이미지 로드 확인
    cy.get('img[alt="업로드된 이미지"]')
      .should('be.visible')
      .and('have.attr', 'src')
      .and('include', 's3.amazonaws.com');
  });
});
```

---

## 📝 체크리스트

프론트엔드 배포 전:

- [ ] Canvas 압축 로직 테스트 완료
- [ ] JPEG 매직 넘버 검증 추가
- [ ] Blob → File 변환 로직 추가
- [ ] 파일 크기 제한 적용 (10MB)
- [ ] 파일 타입 검증 적용
- [ ] S3 업로드 실패 시 폴백 로직 추가
- [ ] 브라우저 콘솔 디버깅 로그 추가
- [ ] 에러 핸들링 추가
- [ ] 로딩 상태 표시
- [ ] 사용자 피드백 추가 (성공/실패 메시지)

---

상세한 트러블슈팅은 `/web_project/IMAGE_UPLOAD_TROUBLESHOOTING.md` 참고
