/**
 * useDocuments Hook
 * 문서 관련 상태와 로직을 관리하는 커스텀 훅
 */

import { useState, useCallback, useEffect } from 'react';
import {
  getSubjectDocuments,
  createDocument,
  updateDocument,
  deleteDocument,
} from '../services/subjectsApi';
import { convertToKST, isSameDate } from '../lib/utils';

/**
 * 문서 관리 훅
 * @param {string} subjectId - 과목 ID
 * @param {Date|null} selectedDate - 선택된 날짜 (필터링용)
 * @returns {Object} 문서 상태 및 액션
 */
export const useDocuments = (subjectId, selectedDate = null) => {
  const [documents, setDocuments] = useState([]);
  const [filteredDocuments, setFilteredDocuments] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [isUpdating, setIsUpdating] = useState(false);
  const [deletingId, setDeletingId] = useState(null);

  // 문서 목록 불러오기
  const loadDocuments = useCallback(async () => {
    if (!subjectId) return;

    try {
      setIsLoading(true);
      setError(null);
      const docs = await getSubjectDocuments(subjectId);
      setDocuments(docs);
    } catch (err) {
      console.error('문서 목록 불러오기 실패:', err);
      setError('문서 목록을 불러오는데 실패했습니다.');
    } finally {
      setIsLoading(false);
    }
  }, [subjectId]);

  // 문서 필터링 (날짜별)
  useEffect(() => {
    if (!selectedDate) {
      setFilteredDocuments(documents);
      return;
    }

    const filtered = documents.filter(doc => {
      if (!doc.created_at) return false;

      // UTC를 KST로 변환
      const kstDate = convertToKST(doc.created_at);

      // 날짜만 비교 (년-월-일)
      return isSameDate(selectedDate, kstDate);
    });

    setFilteredDocuments(filtered);
  }, [documents, selectedDate]);

  // 문서 생성
  const handleCreateDocument = useCallback(async (documentData) => {
    try {
      setError(null);
      await createDocument(documentData);
      await loadDocuments();
      return true;
    } catch (err) {
      console.error('문서 생성 실패:', err);
      setError('문서 생성에 실패했습니다.');
      return false;
    }
  }, [loadDocuments]);

  // 문서 수정
  const handleUpdateDocument = useCallback(async (documentId, updateData) => {
    try {
      setIsUpdating(true);
      setError(null);
      await updateDocument(documentId, updateData);
      await loadDocuments();
      return true;
    } catch (err) {
      console.error('문서 수정 실패:', err);
      setError('문서 수정에 실패했습니다.');
      return false;
    } finally {
      setIsUpdating(false);
    }
  }, [loadDocuments]);

  // 문서 삭제
  const handleDeleteDocument = useCallback(async (documentId) => {
    try {
      setDeletingId(documentId);
      setError(null);
      await deleteDocument(documentId);
      await loadDocuments();
      return true;
    } catch (err) {
      console.error('문서 삭제 실패:', err);
      setError('문서 삭제에 실패했습니다.');
      return false;
    } finally {
      setDeletingId(null);
    }
  }, [loadDocuments]);

  return {
    // 상태
    documents,
    filteredDocuments,
    isLoading,
    error,
    isUpdating,
    deletingId,

    // 액션
    loadDocuments,
    createDocument: handleCreateDocument,
    updateDocument: handleUpdateDocument,
    deleteDocument: handleDeleteDocument,
  };
};
