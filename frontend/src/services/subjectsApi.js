/**
 * Subjects & Documents API Service
 * 과목 및 문서 관련 API 호출 함수들
 */

import { apiRequest, API_ENDPOINTS } from '../config/api';

// ============= Subjects API =============

/**
 * 과목 목록 조회
 */
export const getSubjects = async () => {
  return apiRequest(API_ENDPOINTS.subjects, {
    method: 'GET',
  });
};

/**
 * 과목 생성
 * @param {Object} subjectData - 과목 데이터 { name, color, description }
 */
export const createSubject = async (subjectData) => {
  return apiRequest(API_ENDPOINTS.subjects, {
    method: 'POST',
    body: JSON.stringify(subjectData),
  });
};

/**
 * 과목 상세 조회
 * @param {string} subjectId - 과목 ID
 */
export const getSubjectDetail = async (subjectId) => {
  return apiRequest(API_ENDPOINTS.subjectDetail(subjectId), {
    method: 'GET',
  });
};

/**
 * 과목 수정
 * @param {string} subjectId - 과목 ID
 * @param {Object} updateData - 수정할 데이터 { name?, color?, description? }
 */
export const updateSubject = async (subjectId, updateData) => {
  return apiRequest(API_ENDPOINTS.subjectDetail(subjectId), {
    method: 'PATCH',
    body: JSON.stringify(updateData),
  });
};

/**
 * 과목 삭제
 * @param {string} subjectId - 과목 ID
 */
export const deleteSubject = async (subjectId) => {
  return apiRequest(API_ENDPOINTS.subjectDetail(subjectId), {
    method: 'DELETE',
  });
};

// ============= Documents API =============

/**
 * 문서 생성
 * @param {Object} documentData - 문서 데이터
 * {
 *   subject_id: string,
 *   title: string,
 *   extracted_text?: string,
 *   original_filename?: string,
 *   image_url?: string,
 *   thumbnail_url?: string,
 *   pages?: number,
 *   file_size?: number
 * }
 */
export const createDocument = async (documentData) => {
  return apiRequest(API_ENDPOINTS.documents, {
    method: 'POST',
    body: JSON.stringify(documentData),
  });
};

/**
 * 특정 과목의 문서 목록 조회
 * @param {string} subjectId - 과목 ID
 */
export const getSubjectDocuments = async (subjectId) => {
  return apiRequest(API_ENDPOINTS.subjectDocuments(subjectId), {
    method: 'GET',
  });
};

/**
 * 문서 상세 조회
 * @param {string} documentId - 문서 ID
 */
export const getDocumentDetail = async (documentId) => {
  return apiRequest(API_ENDPOINTS.documentDetail(documentId), {
    method: 'GET',
  });
};

/**
 * 문서 수정
 * @param {string} documentId - 문서 ID
 * @param {Object} updateData - 수정할 데이터 { title?, extracted_text?, pages? }
 */
export const updateDocument = async (documentId, updateData) => {
  return apiRequest(API_ENDPOINTS.documentDetail(documentId), {
    method: 'PATCH',
    body: JSON.stringify(updateData),
  });
};

/**
 * 문서 삭제
 * @param {string} documentId - 문서 ID
 */
export const deleteDocument = async (documentId) => {
  return apiRequest(API_ENDPOINTS.documentDetail(documentId), {
    method: 'DELETE',
  });
};

// ============= Reviews API =============

/**
 * 복습 문서 조회 (오늘의 복습, 밀린 복습)
 * @returns {Promise<{today: Array, overdue: Array, today_count: number, overdue_count: number}>}
 */
export const getReviewDocuments = async () => {
  return apiRequest(API_ENDPOINTS.reviews, {
    method: 'GET',
  });
};

/**
 * AI 텍스트 교정
 * @param {string} documentId - 문서 ID
 * @param {string} originalText - 교정할 원본 텍스트
 * @returns {Promise<{original_text: string, corrected_text: string, model_used: string, timestamp: string}>}
 */
export const aiTextCorrection = async (documentId, originalText) => {
  return apiRequest(`/api/v1/subjects/documents/${documentId}/ai-correction`, {
    method: 'POST',
    body: JSON.stringify({
      original_text: originalText
    }),
  });
};

/**
 * 이미지를 S3에 업로드
 * @param {File} file - 업로드할 이미지 파일
 * @returns {Promise<{image_url: string}>}
 */
export const uploadImageToS3 = async (file) => {
  // Blob인 경우 File 객체로 변환 (filename 보장)
  if (file instanceof Blob && !(file instanceof File)) {
    file = new File([file], 'compressed_image.jpg', {
      type: file.type || 'image/jpeg'
    });
  }

  // FormData 생성
  const formData = new FormData();
  formData.append('file', file);

  // S3 업로드 API 호출
  return apiRequest(`${API_ENDPOINTS.subjects}/upload-image`, {
    method: 'POST',
    body: formData,
    // Content-Type은 브라우저가 자동으로 multipart/form-data로 설정
  });
};
