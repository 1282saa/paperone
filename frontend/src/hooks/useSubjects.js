/**
 * useSubjects Hook
 * 과목 관련 상태와 로직을 관리하는 커스텀 훅
 */

import { useState, useCallback } from 'react';
import { getSubjects, createSubject, updateSubject, deleteSubject } from '../services/subjectsApi';
import { SUBJECT_COLORS } from '../constants';

export const useSubjects = () => {
  const [subjects, setSubjects] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  // 과목 목록 불러오기
  const loadSubjects = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);
      const data = await getSubjects();
      setSubjects(data);
    } catch (err) {
      console.error('과목 목록 조회 실패:', err);
      setError('과목 목록을 불러오는데 실패했습니다.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  // 과목 생성
  const handleCreateSubject = useCallback(async (subjectData) => {
    try {
      setError(null);

      // 랜덤 색상 선택
      const randomColor = SUBJECT_COLORS[Math.floor(Math.random() * SUBJECT_COLORS.length)];

      const newSubjectData = {
        ...subjectData,
        color: randomColor,
        description: "",
      };

      await createSubject(newSubjectData);
      await loadSubjects(); // 목록 새로고침
      return true;
    } catch (err) {
      console.error('과목 추가 실패:', err);
      setError('과목 추가에 실패했습니다.');
      return false;
    }
  }, [loadSubjects]);

  // 과목 수정
  const handleUpdateSubject = useCallback(async (subjectId, updateData) => {
    try {
      setError(null);
      await updateSubject(subjectId, updateData);
      await loadSubjects(); // 목록 새로고침
      return true;
    } catch (err) {
      console.error('과목 수정 실패:', err);
      setError('과목 수정에 실패했습니다.');
      return false;
    }
  }, [loadSubjects]);

  // 과목 삭제
  const handleDeleteSubject = useCallback(async (subjectId) => {
    try {
      setError(null);
      await deleteSubject(subjectId);
      await loadSubjects(); // 목록 새로고침
      return true;
    } catch (err) {
      console.error('과목 삭제 실패:', err);
      setError('과목 삭제에 실패했습니다.');
      return false;
    }
  }, [loadSubjects]);

  return {
    // 상태
    subjects,
    isLoading,
    error,

    // 액션
    loadSubjects,
    createSubject: handleCreateSubject,
    updateSubject: handleUpdateSubject,
    deleteSubject: handleDeleteSubject,
  };
};