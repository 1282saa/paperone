# Frontend Refactoring Guide

## 개요
이 문서는 프론트엔드 코드베이스의 클린 코드 원칙 적용 및 구조화 리팩토링을 설명합니다.

## 리팩토링 원칙

### 1. 단일 책임 원칙 (Single Responsibility Principle)
- 각 컴포넌트와 함수는 하나의 명확한 책임만 갖습니다
- 복잡한 로직은 커스텀 훅으로 분리
- UI 컴포넌트는 재사용 가능하도록 분리

### 2. DRY (Don't Repeat Yourself)
- 중복 코드를 유틸리티 함수로 중앙화
- 공통 상수를 별도 파일로 관리
- 반복되는 UI 패턴을 컴포넌트로 추상화

### 3. 관심사의 분리 (Separation of Concerns)
- 비즈니스 로직과 UI 로직 분리
- API 호출과 상태 관리 분리
- 데이터 처리와 렌더링 분리

## 프로젝트 구조

```
src/
├── components/           # 재사용 가능한 컴포넌트
│   ├── common/          # 공통 UI 컴포넌트
│   │   ├── Button.jsx
│   │   ├── Modal.jsx
│   │   └── BottomSheet.jsx
│   ├── domain/          # 도메인별 컴포넌트
│   │   ├── subjects/
│   │   ├── documents/
│   │   │   └── DocumentListItem.jsx
│   │   ├── reviews/
│   │   └── ocr/
│   │       └── OCRResultModal.jsx
│   └── ui/              # 기본 UI 요소
│       ├── Skeleton.jsx
│       └── icons/
├── hooks/               # 커스텀 훅
│   ├── useSubjects.js   # 과목 관리 훅
│   ├── useDocuments.js  # 문서 관리 훅
│   ├── useOCR.js        # OCR 처리 훅
│   └── useReviews.js    # 복습 관리 훅
├── lib/                 # 유틸리티 함수
│   └── utils.js
├── constants/           # 상수 정의
│   └── index.js
├── services/            # API 서비스
│   ├── authApi.js
│   └── subjectsApi.js
├── config/              # 설정 파일
│   └── api.js
└── screens/             # 페이지 컴포넌트
    └── Screen/
        └── sections/
            └── SubjectDetail/
```

## 주요 개선 사항

### 1. 커스텀 훅 분리

#### `useDocuments` - 문서 관리
```javascript
const {
  filteredDocuments,  // 필터링된 문서 목록
  isLoading,          // 로딩 상태
  deletingId,         // 삭제 중인 문서 ID
  loadDocuments,      // 문서 목록 로드
  createDocument,     // 문서 생성
  updateDocument,     // 문서 수정
  deleteDocument,     // 문서 삭제
} = useDocuments(subjectId, selectedDate);
```

**책임:**
- 문서 목록 조회 및 관리
- 날짜별 필터링
- CRUD 작업 처리
- 에러 핸들링

#### `useOCR` - OCR 처리
```javascript
const {
  isProcessing,       // OCR 처리 중 상태
  ocrResult,          // OCR 결과
  uploadedImageFile,  // 업로드된 이미지
  editableText,       // 편집 가능한 텍스트
  processImage,       // 이미지 처리 및 OCR
  uploadImage,        // 이미지 압축 및 업로드
  setEditableText,    // 텍스트 수정
  reset,              // 상태 초기화
} = useOCR();
```

**책임:**
- 이미지 유효성 검사
- OCR 처리 (AWS Textract)
- 이미지 압축 및 S3 업로드
- OCR 상태 관리

### 2. 유틸리티 함수 중앙화

#### `lib/utils.js`
- `compressImage()` - 이미지 압축 (Canvas API)
- `convertToKST()` - UTC → KST 시간 변환
- `isSameDate()` - 날짜 비교 (년-월-일만)
- `formatDateWithDots()` - 날짜 포맷팅 (YYYY.MM.DD)
- `formatDate()` - 일반 날짜 포맷팅
- `formatFileSize()` - 파일 크기 포맷팅
- `storage` - 로컬 스토리지 헬퍼

### 3. 상수 중앙화

#### `constants/index.js`
```javascript
// 이미지 압축 설정
export const IMAGE_COMPRESSION = {
  QUALITY: 0.7,        // JPEG 품질 (0-1)
  MAX_WIDTH: 1024,     // 최대 너비 (px)
  MAX_HEIGHT: 1024,    // 최대 높이 (px)
  OUTPUT_FORMAT: 'image/jpeg',
};

// 과목 색상 팔레트
export const SUBJECT_COLORS = [
  "#E8E8FF", "#FFE8E8", "#E8FFE8",
  "#FFFFE8", "#FFE8FF", "#E8FFFF"
];

// 파일 크기 제한
export const FILE_LIMITS = {
  MAX_SIZE: 10 * 1024 * 1024, // 10MB
  ALLOWED_TYPES: ['image/jpeg', 'image/png', 'application/pdf'],
};
```

### 4. 컴포넌트 분리

#### `DocumentListItem` - 문서 리스트 아이템
**Props:**
- `document` - 문서 객체
- `onClick` - 클릭 핸들러
- `onEdit` - 수정 핸들러
- `onDelete` - 삭제 핸들러
- `isDeleting` - 삭제 중 여부

**책임:**
- 문서 정보 표시
- 수정/삭제 버튼 UI
- 호버 인터랙션

#### `BottomSheet` - 하단 모달
**Props:**
- `isOpen` - 열림 여부
- `onClose` - 닫기 핸들러
- `title` - 제목
- `children` - 자식 컴포넌트

**책임:**
- 하단에서 올라오는 모달 UI
- 배경 클릭 시 닫기
- 애니메이션 처리

#### `OCRResultModal` - OCR 결과 모달
**Props:**
- `isOpen` - 열림 여부
- `onClose` - 닫기 핸들러
- `onSave` - 저장 핸들러
- `ocrResult` - OCR 결과
- `imageFile` - 원본 이미지
- `editableText` - 편집 가능한 텍스트
- `onTextChange` - 텍스트 변경 핸들러
- `isSaving` - 저장 중 여부

**책임:**
- 좌우 분할 레이아웃 (이미지/텍스트)
- 전체화면 토글
- 텍스트 편집 기능

## 리팩토링 전후 비교

### SubjectDetail 컴포넌트

#### Before (897 lines)
- 모든 로직이 하나의 파일에 집중
- 중복된 날짜 처리 로직
- 이미지 압축 로직 내장
- 인라인 모달 컴포넌트
- 반복되는 문서 아이템 JSX

#### After (430 lines, 52% 감소)
- 커스텀 훅으로 로직 분리
- 재사용 가능한 컴포넌트 활용
- 명확한 책임 분리
- 가독성 향상
- 테스트 용이성 증가

### 코드 예시

#### Before
```javascript
// 이미지 압축 함수 (컴포넌트 내부)
const compressImage = (file, quality = 0.7, maxWidth = 1024) => {
  return new Promise((resolve, reject) => {
    // ... 50+ lines of code
  });
};

// 날짜 필터링 (useEffect 내부)
useEffect(() => {
  if (!selectedDate) {
    setFilteredDocuments(documents);
    return;
  }

  const filtered = documents.filter(doc => {
    if (!doc.created_at) return false;
    const docDate = new Date(doc.created_at);
    const kstOffset = 9 * 60;
    // ... 10+ lines of date logic
  });

  setFilteredDocuments(filtered);
}, [documents, selectedDate]);
```

#### After
```javascript
// 유틸리티 함수 사용
import { compressImage, convertToKST, isSameDate } from '../lib/utils';

// 커스텀 훅 사용
const {
  filteredDocuments,
  isLoading,
  loadDocuments,
  createDocument,
} = useDocuments(subjectId, selectedDate);

// 훅이 필터링 자동 처리
```

## 성능 개선

### 1. 메모이제이션
- `useCallback`으로 불필요한 함수 재생성 방지
- 커스텀 훅의 의존성 배열 최적화

### 2. 코드 스플리팅
- 컴포넌트 분리로 번들 크기 최적화 가능성
- 향후 동적 import 적용 가능

### 3. 재렌더링 최소화
- 상태 관리 분리로 불필요한 재렌더링 감소
- 명확한 의존성 관리

## 테스트 용이성

### Before
- 거대한 컴포넌트 테스트 어려움
- 로직이 UI와 강하게 결합
- Mock 설정 복잡

### After
- 각 훅을 독립적으로 테스트 가능
- 컴포넌트는 Props만 테스트
- 유틸리티 함수는 순수 함수로 테스트 간단

## 향후 개선 방향

### 1. TypeScript 도입
- 타입 안정성 확보
- 개발 경험 향상
- 리팩토링 안정성 증가

### 2. 상태 관리 라이브러리
- Redux Toolkit 또는 Zustand 도입 고려
- 전역 상태 관리 개선
- 서버 상태 관리 (React Query)

### 3. 테스트 코드 작성
- 커스텀 훅 단위 테스트
- 컴포넌트 통합 테스트
- E2E 테스트 (Playwright/Cypress)

### 4. 코드 스플리팅
- 라우트 기반 코드 스플리팅
- 컴포넌트 레이지 로딩
- 번들 크기 최적화

### 5. 접근성 개선
- ARIA 속성 추가
- 키보드 네비게이션 지원
- 스크린 리더 최적화

## 컨벤션

### 파일명
- 컴포넌트: `PascalCase.jsx`
- 훅: `camelCase.js` (use 접두사)
- 유틸리티: `camelCase.js`
- 상수: `UPPER_SNAKE_CASE`

### 함수명
- 이벤트 핸들러: `handle` 접두사
- 유틸리티 함수: 동사로 시작
- 불린 함수: `is`, `has`, `should` 접두사

### 주석
- JSDoc 스타일로 함수 문서화
- 복잡한 로직에만 인라인 주석
- 컴포넌트 파일 상단에 설명 주석

## 마이그레이션 가이드

다른 컴포넌트를 리팩토링할 때:

1. **상태 분석**: 어떤 상태가 있는가?
2. **로직 추출**: 비즈니스 로직을 커스텀 훅으로
3. **UI 분리**: 반복되는 UI를 컴포넌트로
4. **유틸리티 활용**: 공통 함수는 `utils.js`로
5. **상수 정의**: 매직 넘버/문자열을 `constants`로
6. **테스트**: 변경 전후 동작 확인

## 참고 자료

- [React Official Docs - Hooks](https://react.dev/reference/react)
- [Clean Code JavaScript](https://github.com/ryanmcdermott/clean-code-javascript)
- [React Design Patterns](https://www.patterns.dev/posts/react-patterns)
