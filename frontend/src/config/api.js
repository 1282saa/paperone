/**
 * API Configuration
 * 배포된 백엔드 API 엔드포인트 설정
 */

export const API_BASE_URL = 'https://y1ec4xig1c.execute-api.us-east-1.amazonaws.com/dev';

export const API_ENDPOINTS = {
  // Health Check
  health: '/health',

  // Subjects (과목)
  subjects: '/api/v1/subjects',
  subjectDetail: (subjectId) => `/api/v1/subjects/${subjectId}`,

  // Documents (문서)
  documents: '/api/v1/subjects/documents',
  documentDetail: (documentId) => `/api/v1/subjects/documents/${documentId}`,
  subjectDocuments: (subjectId) => `/api/v1/subjects/${subjectId}/documents`,

  // Reviews (복습)
  reviews: '/api/v1/subjects/reviews',
};

// API 요청 헬퍼 함수
export const apiRequest = async (endpoint, options = {}) => {
  const url = `${API_BASE_URL}${endpoint}`;

  const defaultOptions = {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  };

  // 인증 토큰이 있으면 추가
  const token = localStorage.getItem('access_token');
  if (token) {
    defaultOptions.headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(url, {
    ...defaultOptions,
    ...options,
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(error.detail || `HTTP error! status: ${response.status}`);
  }

  // 204 No Content의 경우 본문이 없으므로 null 반환
  if (response.status === 204) {
    return null;
  }

  return response.json();
};
