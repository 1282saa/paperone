/**
 * AI 챗봇 API 서비스
 */

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

/**
 * API 요청 헬퍼 함수
 */
const apiRequest = async (endpoint, options = {}) => {
  const token = localStorage.getItem('access_token');

  const config = {
    ...options,
    headers: {
      ...options.headers,
      ...(token && { Authorization: `Bearer ${token}` }),
      ...(!(options.body instanceof FormData) && { 'Content-Type': 'application/json' }),
    },
  };

  const response = await fetch(`${API_BASE_URL}${endpoint}`, config);

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.detail || `API 요청 실패: ${response.status}`);
  }

  return response.json();
};

/**
 * AI 튜터와 대화
 * @param {string} message - 사용자 메시지
 * @param {string|null} conversationId - 대화 ID (선택)
 * @returns {Promise<{message: string, conversation_id: string}>}
 */
export const chatWithAI = async (message, conversationId = null) => {
  return apiRequest('/api/v1/ai/tutor', {
    method: 'POST',
    body: JSON.stringify({
      message,
      conversation_id: conversationId,
    }),
  });
};

/**
 * 사용자의 대화 목록 조회
 * @returns {Promise<{conversations: Array}>}
 */
export const getConversations = async () => {
  return apiRequest('/api/v1/ai/tutor/conversations', {
    method: 'GET',
  });
};

/**
 * 특정 대화의 전체 내용 조회
 * @param {string} conversationId - 대화 ID
 * @returns {Promise<{messages: Array}>}
 */
export const getConversationDetail = async (conversationId) => {
  return apiRequest(`/api/v1/ai/tutor/conversations/${conversationId}`, {
    method: 'GET',
  });
};
