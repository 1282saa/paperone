/**
 * Auth API Service
 * 인증 관련 API 호출 함수들
 */

import { apiRequest, API_ENDPOINTS } from '../config/api';

/**
 * 로그인
 * @param {string} email - 이메일
 * @param {string} password - 비밀번호
 */
export const login = async (email, password) => {
  return apiRequest('/api/v1/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
};

/**
 * 회원가입
 * @param {string} email - 이메일
 * @param {string} password - 비밀번호
 * @param {string} name - 이름
 */
export const register = async (email, password, name) => {
  return apiRequest('/api/v1/auth/register', {
    method: 'POST',
    body: JSON.stringify({ email, password, name }),
  });
};

/**
 * 토큰 갱신
 * @param {string} refreshToken - 리프레시 토큰
 */
export const refreshToken = async (refreshToken) => {
  return apiRequest('/api/v1/auth/refresh', {
    method: 'POST',
    body: JSON.stringify({ refresh_token: refreshToken }),
  });
};

/**
 * 로그아웃 (로컬 토큰 삭제)
 */
export const logout = () => {
  localStorage.removeItem('access_token');
  localStorage.removeItem('id_token');
  localStorage.removeItem('refresh_token');
};

/**
 * 이메일 인증 코드 확인
 * @param {string} email - 이메일
 * @param {string} code - 인증 코드
 */
export const confirmEmail = async (email, code) => {
  return apiRequest(`/api/v1/auth/confirm?email=${encodeURIComponent(email)}&code=${encodeURIComponent(code)}`, {
    method: 'POST',
  });
};

/**
 * 인증 코드 재전송
 * @param {string} email - 이메일
 */
export const resendCode = async (email) => {
  return apiRequest(`/api/v1/auth/resend-code?email=${encodeURIComponent(email)}`, {
    method: 'POST',
  });
};

/**
 * 현재 로그인 상태 확인
 */
export const isAuthenticated = () => {
  return !!localStorage.getItem('access_token');
};

/**
 * 현재 사용자 정보 가져오기
 */
export const getCurrentUser = async () => {
  return apiRequest('/api/v1/auth/me', {
    method: 'GET',
  });
};
