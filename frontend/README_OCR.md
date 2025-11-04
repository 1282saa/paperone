# AWS Textract OCR 설정 가이드

이 프로젝트는 AWS Textract를 사용하여 이미지에서 텍스트를 추출하는 OCR 기능을 제공합니다.

## 1. AWS 계정 설정

### 1.1 IAM 사용자 생성
1. [AWS IAM 콘솔](https://console.aws.amazon.com/iam/)에 접속합니다
2. "사용자" 메뉴에서 "사용자 추가"를 클릭합니다
3. 사용자 이름을 입력하고 "액세스 키 - 프로그래밍 방식 액세스"를 선택합니다
4. "권한 설정"에서 "기존 정책 직접 연결"을 선택합니다
5. "AmazonTextractFullAccess" 정책을 검색하여 선택합니다
6. 태그는 선택사항입니다 (건너뛰어도 됩니다)
7. 검토 후 "사용자 만들기"를 클릭합니다
8. **중요**: 액세스 키 ID와 시크릿 액세스 키를 안전한 곳에 저장합니다 (다시 확인할 수 없습니다)

### 1.2 권한 확인
생성한 IAM 사용자에게 다음 권한이 있는지 확인합니다:
- `textract:DetectDocumentText`
- `textract:AnalyzeDocument`

## 2. 프로젝트 설정

### 2.1 환경 변수 파일 생성
```bash
# .env.example 파일을 .env로 복사
cp .env.example .env
```

### 2.2 AWS 자격 증명 입력
`.env` 파일을 열고 다음 값들을 입력합니다:

```env
VITE_AWS_REGION=us-east-1
VITE_AWS_ACCESS_KEY_ID=여기에_액세스_키_ID_입력
VITE_AWS_SECRET_ACCESS_KEY=여기에_시크릿_액세스_키_입력
```

**주의사항:**
- `.env` 파일은 절대 git에 커밋하지 마세요
- 프로덕션 환경에서는 AWS Cognito나 IAM Role을 사용하는 것이 더 안전합니다
- 현재 설정은 개발 환경용입니다

## 3. 사용 방법

### 3.1 기능 위치
1. 좌측 메뉴에서 "백지복습" 클릭
2. "내 과목" 섹션에서 과목 카드 클릭 (예: 국어, 영어, 수학, 한국사)
3. 우측 하단의 "오늘한장 작성하기" 버튼 클릭
4. 바텀시트에서 "사진 찍기" 또는 "파일 업로드" 선택

### 3.2 지원 파일 형식
- JPG/JPEG
- PNG
- BMP
- TIFF

### 3.3 파일 크기 제한
- 최대 5MB

### 3.4 OCR 결과
텍스트 추출이 완료되면 다음 정보를 확인할 수 있습니다:
- 추출된 텍스트 (전체)
- 신뢰도 (0-100%)
- 각 줄별 텍스트와 신뢰도

## 4. 비용 안내

AWS Textract 요금 (2024년 기준):
- 처음 1백만 페이지: $1.50/1,000 페이지
- 매월 첫 1,000페이지는 무료 (AWS 프리 티어)

자세한 내용은 [AWS Textract 요금 페이지](https://aws.amazon.com/ko/textract/pricing/)를 참조하세요.

## 5. 문제 해결

### "AWS 자격 증명이 유효하지 않습니다" 오류
- `.env` 파일의 액세스 키 ID와 시크릿 키가 올바른지 확인하세요
- IAM 사용자에게 Textract 권한이 있는지 확인하세요

### "지원하지 않는 이미지 형식입니다" 오류
- JPG, PNG, BMP, TIFF 형식의 파일만 지원됩니다
- 파일 확장자가 올바른지 확인하세요

### "파일 크기는 5MB 이하여야 합니다" 오류
- 이미지 파일 크기를 줄여주세요
- 이미지 압축 도구를 사용하거나 해상도를 낮춰주세요

### "요청이 너무 많습니다" 오류
- AWS API 호출 제한에 도달했습니다
- 잠시 후 다시 시도해주세요

## 6. 코드 구조

### 파일 위치
- OCR 서비스: `src/utils/ocrService.js`
- 사용 컴포넌트: `src/screens/Screen/sections/SubjectDetail/SubjectDetail.jsx`

### 주요 함수
- `extractTextFromImage(file)`: 이미지에서 텍스트 추출
- `validateImageFile(file)`: 파일 유효성 검사
- `processImageFile(file)`: 파일 처리 및 OCR 실행

## 7. 향후 개선 사항

- [ ] 추출된 텍스트 편집 기능
- [ ] 문서 저장 및 관리 기능
- [ ] 다중 페이지 문서 처리
- [ ] 표 및 양식 인식 (AnalyzeDocument API 사용)
- [ ] 프로덕션 환경용 보안 강화 (AWS Cognito 통합)
