/**
 * Application Constants
 * 팀원들이 공통으로 사용하는 상수들을 중앙 관리
 */

// 색상 팔레트 (디자인 시스템)
export const COLORS = {
  primary: {
    main: '#00c288',
    hover: '#00a876',
  },
  danger: {
    main: '#ff6b6b',
    hover: '#ff5252',
  },
  background: {
    main: '#f1f3f5',
    light: '#f8f9fa',
  },
  text: {
    primary: '#111111',
    secondary: '#767676',
    muted: '#505050',
  },
};

// 애니메이션 duration
export const ANIMATION = {
  fast: '150ms',
  normal: '300ms',
  slow: '500ms',
};

// 브레이크포인트
export const BREAKPOINTS = {
  sm: '640px',
  md: '768px',
  lg: '1024px',
  xl: '1280px',
};

// 메뉴 타입
export const MENU_TYPES = {
  HOME: 'home',
  REVIEW: 'review',
  STATS: 'stats',
};

// API 관련 상수
export const API_STATUS = {
  IDLE: 'idle',
  LOADING: 'loading',
  SUCCESS: 'success',
  ERROR: 'error',
};

// 파일 크기 제한 (바이트)
export const FILE_LIMITS = {
  MAX_SIZE: 10 * 1024 * 1024, // 10MB
  ALLOWED_TYPES: ['image/jpeg', 'image/png', 'application/pdf'],
};

// 이미지 압축 설정
export const IMAGE_COMPRESSION = {
  QUALITY: 0.7, // JPEG 압축 품질 (0-1)
  MAX_WIDTH: 1024, // 최대 너비 (px)
  MAX_HEIGHT: 1024, // 최대 높이 (px)
  OUTPUT_FORMAT: 'image/jpeg', // 출력 포맷
};

// 과목 색상 팔레트
export const SUBJECT_COLORS = [
  "#E8E8FF",
  "#FFE8E8",
  "#E8FFE8",
  "#FFFFE8",
  "#FFE8FF",
  "#E8FFFF"
];