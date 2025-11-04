/**
 * ReviewPage Component
 * 리팩토링된 복습 페이지 메인 컴포넌트
 * - 단일 책임 원칙 준수
 * - Custom Hooks를 통한 로직 분리
 * - 재사용 가능한 컴포넌트 활용
 */

import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { SubjectDetail } from '../../screens/Screen/sections/SubjectDetail/SubjectDetail';
import { DocumentDetail } from '../../screens/Screen/sections/DocumentDetail';
import { TodayReviews } from '../../components/domain/reviews/TodayReviews';
import { OverdueReviews } from '../../components/domain/reviews/OverdueReviews';
import { SubjectsList } from '../../components/domain/subjects/SubjectsList';
import { SubjectModal } from '../../components/domain/subjects/SubjectModal';
import { useSubjects } from '../../hooks/useSubjects';
import { useReviews } from '../../hooks/useReviews';

export const ReviewPage = ({ autoSelectToday = false, selectedDate, setSelectedDate }) => {
  // React Router hooks
  const { subjectId, documentId } = useParams();
  const navigate = useNavigate();

  // State: 현재 선택된 과목 (URL 파라미터에서 가져옴)
  const [selectedSubject, setSelectedSubject] = useState(null);

  // State: 모달 상태 관리
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingSubject, setEditingSubject] = useState(null);

  // Custom Hooks
  const {
    subjects,
    isLoading: isLoadingSubjects,
    error: subjectsError,
    loadSubjects,
    createSubject,
    updateSubject,
    deleteSubject
  } = useSubjects();

  const {
    reviewData,
    isLoading: isLoadingReviews,
    error: reviewsError,
    loadReviews,
    toggleReview,
    calculateOverdueDays
  } = useReviews();

  // Effect: autoSelectToday가 true이고 selectedDate가 null이면 오늘 날짜로 설정
  useEffect(() => {
    if (autoSelectToday && !selectedDate) {
      setSelectedDate(new Date());
    }
  }, [autoSelectToday, selectedDate, setSelectedDate]);

  // Effect: 컴포넌트 마운트 시 데이터 로드
  useEffect(() => {
    loadSubjects();
    loadReviews();
  }, [loadSubjects, loadReviews]);

  // Effect: URL 파라미터에 따라 선택된 과목 설정
  useEffect(() => {
    if (subjectId && subjects.length > 0) {
      const subject = subjects.find(s => s.subject_id === subjectId);
      if (subject) {
        setSelectedSubject(subject);
      }
    } else {
      setSelectedSubject(null);
    }
  }, [subjectId, subjects]);

  // Handlers: 과목 관련
  const handleAddSubject = () => {
    setShowAddModal(true);
  };

  const handleSubjectClick = (subject) => {
    // Navigate to subject detail page
    navigate(`/review/subject/${subject.subject_id}`);
  };

  const handleEditSubject = (e, subject) => {
    e.stopPropagation();
    setEditingSubject(subject);
  };

  const handleDeleteSubject = async (e, subject) => {
    e.stopPropagation();
    await deleteSubject(subject.subject_id);
  };

  const handleBackToList = () => {
    // Navigate back to review list
    navigate('/review');
  };

  // Handlers: 모달 관련
  const handleCreateSubject = async (data) => {
    const success = await createSubject(data);
    if (success) {
      setShowAddModal(false);
    }
    return success;
  };

  const handleUpdateSubject = async (data) => {
    const success = await updateSubject(editingSubject.subject_id, data);
    if (success) {
      setEditingSubject(null);
    }
    return success;
  };

  // DocumentDetail 페이지를 보여줄지 결정 (가장 구체적인 라우트부터 체크)
  if (documentId && selectedSubject) {
    return (
      <DocumentDetail
        documentId={documentId}
        onBack={() => navigate(`/review/subject/${selectedSubject.subject_id}`)}
      />
    );
  }

  // 과목 상세 페이지를 보여줄지 목록을 보여줄지 결정
  if (selectedSubject) {
    return (
      <SubjectDetail
        subjectName={selectedSubject.name}
        subjectId={selectedSubject.subject_id}
        selectedDate={selectedDate}
        onBack={handleBackToList}
      />
    );
  }

  return (
    <div className="flex-1 h-full bg-[#f1f3f5] rounded-[40px_0px_0px_40px] overflow-auto flex items-start justify-center">
      <div className="relative w-full max-w-[1178px] px-[60px] py-[60px]">

        {/* Error Display */}
        {(subjectsError || reviewsError) && (
          <div className="mb-6 p-4 bg-red-100 border border-red-400 text-red-700 rounded-lg">
            {subjectsError || reviewsError}
          </div>
        )}

        {/* Today's Reviews Section */}
        <TodayReviews
          reviewData={reviewData}
          isLoading={isLoadingReviews}
          onToggleReview={toggleReview}
        />

        {/* Overdue Reviews Section */}
        <OverdueReviews
          reviewData={reviewData}
          isLoading={isLoadingReviews}
          onToggleReview={toggleReview}
          calculateOverdueDays={calculateOverdueDays}
        />

        {/* My Subjects Section */}
        <SubjectsList
          subjects={subjects}
          isLoading={isLoadingSubjects}
          onAddSubject={handleAddSubject}
          onSubjectClick={handleSubjectClick}
          onEditSubject={handleEditSubject}
          onDeleteSubject={handleDeleteSubject}
        />

        {/* 과목 추가 모달 */}
        <SubjectModal
          isOpen={showAddModal}
          onClose={() => setShowAddModal(false)}
          onSubmit={handleCreateSubject}
          mode="create"
        />

        {/* 과목 수정 모달 */}
        <SubjectModal
          isOpen={!!editingSubject}
          onClose={() => setEditingSubject(null)}
          onSubmit={handleUpdateSubject}
          mode="edit"
          initialValue={editingSubject?.name || ""}
        />
      </div>
    </div>
  );
};