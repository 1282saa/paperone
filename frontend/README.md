# 오늘 한 장 Frontend

React + TypeScript + Vite로 구축된 학습 관리 플랫폼 프론트엔드

## 🚀 시작하기

### 환경 설정

```bash
# 의존성 설치
npm install

# 환경변수 설정
cp .env.example .env

# 개발 서버 실행
npm run dev
```

### 빌드

```bash
# 프로덕션 빌드
npm run build

# 빌드 미리보기
npm run preview
```

## 📁 프로젝트 구조

```
frontend/
├── src/
│   ├── api/              # API 클라이언트 및 엔드포인트
│   ├── components/       # 재사용 가능한 컴포넌트
│   │   ├── layout/       # 레이아웃 컴포넌트
│   │   ├── home/         # 홈 페이지 컴포넌트
│   │   ├── learning/     # 학습 관련 컴포넌트
│   │   ├── calendar/     # 캘린더 컴포넌트
│   │   └── common/       # 공통 컴포넌트
│   ├── pages/            # 페이지 컴포넌트
│   ├── hooks/            # 커스텀 훅
│   ├── store/            # 상태 관리 (Zustand)
│   ├── types/            # TypeScript 타입 정의
│   └── utils/            # 유틸리티 함수
├── .env.example          # 환경변수 예시
└── package.json
```

## 🛠 기술 스택

- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite
- **Routing**: React Router v6
- **State Management**: Zustand
- **Data Fetching**: TanStack Query (React Query)
- **HTTP Client**: Axios
- **Styling**: CSS Modules

## 📱 주요 페이지

### 홈 (/)
- 환영 메시지
- 복습 지속률 통계
- D-Day 정보
- 오늘의 할 일 개수
- 빠른 시작 버튼

### 백지복습 (/blank-review)
- 백지 복습 목록
- 새 백지 작성
- 복습 기록

### 오늘의 학습 (/today-learning)
- 일일 할 일 목록
- 학습 세션 기록

### 학습 통계 (/statistics)
- 일별/주간 통계
- 학습 시간 추이
- 복습 지속률 그래프

### AI 기능
- AI 문제 생성 (/ai-question)
- AI 튜터 복습이 (/ai-tutor)

## 🎨 디자인 시스템

### 컬러 팔레트
- Primary: `#00C288` (Green)
- Error: `#F1706D` (Red)
- Background: `#F1F3F5` (Light Gray)
- Text Primary: `#111111`
- Text Secondary: `#767676`

### Typography
- Font Family: Pretendard Variable

## 🔗 API 연동

백엔드 API와 통신하기 위해 Axios를 사용합니다.

```typescript
// 예시: 홈 통계 가져오기
import { statisticsAPI } from './api/endpoints';

const { data } = await statisticsAPI.getHomeStatistics();
```

## 🔐 인증

JWT 토큰 기반 인증을 사용합니다. 토큰은 localStorage에 저장됩니다.

```typescript
// 로그인
const response = await authAPI.login(email, password);
localStorage.setItem('access_token', response.data.access_token);
```

## 📄 환경변수

`.env` 파일에 다음 변수를 설정하세요:

```
VITE_API_BASE_URL=http://localhost:8000
```

## 🧪 개발 팁

- 컴포넌트는 기능별로 분리
- API 호출은 React Query 사용
- 전역 상태는 Zustand 사용
- 타입 안정성을 위해 TypeScript 적극 활용

## 📄 라이선스

Proprietary
