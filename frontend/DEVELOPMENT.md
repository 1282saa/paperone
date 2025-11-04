# 🚀 개발 가이드

## 📁 폴더 구조 규칙

### 컴포넌트 배치 가이드

```
src/
├── components/
│   ├── ui/              # 재사용 가능한 UI 컴포넌트
│   ├── common/          # 공통 비즈니스 컴포넌트
│   └── domain/          # 도메인별 특화 컴포넌트
├── pages/               # 페이지 컴포넌트
├── hooks/               # 커스텀 훅
├── lib/                 # 유틸리티, 헬퍼 함수
├── constants/           # 상수 정의
└── services/            # API 호출 로직
```

### 컴포넌트 네이밍 규칙

- **PascalCase**: 컴포넌트명 (예: `ReviewPage`, `SubjectCard`)
- **camelCase**: 함수, 변수명 (예: `useSubjects`, `handleClick`)
- **UPPER_SNAKE_CASE**: 상수 (예: `API_BASE_URL`, `COLORS`)

## 🎯 Import 규칙

### 권장 Import 순서
```jsx
// 1. React/라이브러리
import React, { useState, useEffect } from 'react';

// 2. 내부 컴포넌트 (ui → common → domain 순)
import { Button, Modal } from '@/components/ui';
import { ReviewCard } from '@/components/common';

// 3. 훅, 유틸리티
import { useSubjects } from '@/hooks/useSubjects';
import { formatDate } from '@/lib/utils';

// 4. 상수
import { COLORS, MENU_TYPES } from '@/constants';
```

### 배럴 Export 활용
```jsx
// ✅ 권장: 한 줄로 깔끔하게
import { Button, Modal, CheckIcon } from '@/components/ui';

// ❌ 비권장: 개별 import
import { Button } from '@/components/ui/button';
import { Modal } from '@/components/ui/modal';
import { CheckIcon } from '@/components/ui/icons';
```

## 🔧 개발 패턴

### 1. 커스텀 훅 활용
```jsx
// 비즈니스 로직은 훅으로 분리
const { subjects, isLoading, createSubject } = useSubjects();
```

### 2. 상수 활용
```jsx
// 하드코딩 대신 상수 사용
const [activeMenu, setActiveMenu] = useState(MENU_TYPES.HOME);
```

### 3. 유틸리티 함수 활용
```jsx
// 공통 로직은 lib/utils에서 import
const formattedDate = formatDate(createdAt, 'YYYY-MM-DD');
```

## 📝 컴포넌트 작성 규칙

### JSDoc 주석 필수
```jsx
/**
 * SubjectCard Component
 * 개별 과목 카드를 렌더링하는 컴포넌트
 * @param {Object} subject - 과목 정보
 * @param {Function} onSubjectClick - 과목 클릭 핸들러
 */
export const SubjectCard = ({ subject, onSubjectClick }) => {
  // ...
};
```

### Props 구조 분해 할당
```jsx
// ✅ 권장
export const Modal = ({ isOpen, onClose, title, children }) => {

// ❌ 비권장
export const Modal = (props) => {
  const { isOpen, onClose } = props;
```

## 🎨 스타일링 규칙

### Tailwind 클래스 순서
```jsx
// 레이아웃 → 크기 → 색상 → 효과 순
className="flex items-center w-full h-12 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
```

### 상수 색상 활용
```jsx
// ✅ 권장: 상수 사용
style={{ backgroundColor: COLORS.primary.main }}

// ❌ 비권장: 하드코딩
style={{ backgroundColor: '#00c288' }}
```

## 🧪 팀 협업 규칙

### 1. 브랜치 네이밍
- `feature/컴포넌트명` (예: `feature/subject-modal`)
- `fix/이슈설명` (예: `fix/login-validation`)
- `refactor/영역명` (예: `refactor/icon-components`)

### 2. 커밋 메시지
```
feat: Add subject deletion functionality
fix: Resolve login validation bug
refactor: Consolidate icon components
docs: Update development guide
```

### 3. PR 규칙
- 한 PR당 하나의 기능/수정사항
- 리뷰어 최소 1명 지정
- 테스트 통과 필수

## 📚 추천 도구

- **VS Code Extensions**: ES7+ React snippets, Tailwind IntelliSense
- **포맷팅**: Prettier
- **린팅**: ESLint
- **상태 관리**: Zustand (향후 고려)
- **폼 관리**: React Hook Form (향후 고려)