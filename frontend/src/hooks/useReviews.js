/**
 * useReviews Hook
 * 복습 관련 상태와 로직을 관리하는 커스텀 훅
 */

import { useState, useCallback } from 'react';
import { getReviewDocuments } from '../services/subjectsApi';

export const useReviews = () => {
  const [reviewData, setReviewData] = useState({
    today: [],
    overdue: [],
    today_count: 0,
    overdue_count: 0
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  // 복습 데이터 불러오기
  const loadReviews = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);
      const data = await getReviewDocuments();
      setReviewData(data);
    } catch (err) {
      console.error('복습 데이터 조회 실패:', err);
      // 인증 에러나 API 에러 시 에러 메시지 표시하지 않고 기본값 설정
      setReviewData({
        today: [],
        overdue: [],
        today_count: 0,
        overdue_count: 0
      });
      setError(null); // 에러 메시지 표시하지 않음
    } finally {
      setIsLoading(false);
    }
  }, []);

  // 복습 항목 체크박스 토글
  const handleToggleReview = useCallback((documentId) => {
    console.log("Toggle review:", documentId);
    // TODO: 실제 API 연동 시 구현
  }, []);

  // 밀린 일수 계산 헬퍼 함수
  const calculateOverdueDays = useCallback((createdAt) => {
    const createdDate = new Date(createdAt);
    const today = new Date();
    const diffTime = Math.abs(today - createdDate);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }, []);

  return {
    // 상태
    reviewData,
    isLoading,
    error,

    // 액션
    loadReviews,
    toggleReview: handleToggleReview,

    // 헬퍼
    calculateOverdueDays,
  };
};