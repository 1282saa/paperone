import React, { useState, useEffect } from "react";
import { SubjectDetail } from "../SubjectDetail/SubjectDetail";
import { getSubjects, createSubject, updateSubject, deleteSubject, getReviewDocuments } from "../../../../services/subjectsApi";
import { ReviewItemSkeleton, CardSkeleton } from "../../../../components/ui/Skeleton";

export const ReviewContent = ({ autoSelectToday = false, selectedDate, setSelectedDate }) => {
  // State: 현재 선택된 과목 (null이면 목록, 과목 객체면 상세)
  const [selectedSubject, setSelectedSubject] = useState(null);

  // Effect: autoSelectToday가 true이고 selectedDate가 null이면 오늘 날짜로 설정
  useEffect(() => {
    if (autoSelectToday && !selectedDate) {
      setSelectedDate(new Date());
    }
  }, [autoSelectToday, selectedDate, setSelectedDate]);

  // State: 현재 표시 중인 주의 시작 날짜
  const [weekStartDate, setWeekStartDate] = useState(() => {
    const today = new Date();
    const day = today.getDay(); // 0(일) ~ 6(토)
    const diff = today.getDate() - day; // 이번 주 일요일
    return new Date(today.setDate(diff));
  });

  // State: 주차 정보
  const [currentWeek, setCurrentWeek] = useState("2025년 10월 2주차");

  // State: 복습 데이터 (API에서 가져오기)
  const [reviewData, setReviewData] = useState({
    today: [],
    overdue: [],
    today_count: 0,
    overdue_count: 0
  });
  const [isLoadingReviews, setIsLoadingReviews] = useState(true);

  // State: 내 과목들 (백엔드에서 불러오기)
  const [subjects, setSubjects] = useState([]);
  const [isLoadingSubjects, setIsLoadingSubjects] = useState(true);

  // State: 과목 추가 모달
  const [showAddSubjectModal, setShowAddSubjectModal] = useState(false);
  const [newSubjectName, setNewSubjectName] = useState("");
  const [isAddingSubject, setIsAddingSubject] = useState(false);

  // State: 과목 수정 모달
  const [editingSubject, setEditingSubject] = useState(null);
  const [editSubjectName, setEditSubjectName] = useState("");
  const [isUpdatingSubject, setIsUpdatingSubject] = useState(false);

  // Effect: 컴포넌트 마운트 시 과목 목록과 복습 데이터 불러오기
  useEffect(() => {
    loadSubjects();
    loadReviews();
  }, []);

  // Function: 과목 목록 불러오기
  const loadSubjects = async () => {
    try {
      setIsLoadingSubjects(true);
      const data = await getSubjects();
      setSubjects(data);
    } catch (error) {
      console.error('과목 목록 조회 실패:', error);
      alert('과목 목록을 불러오는데 실패했습니다.');
    } finally {
      setIsLoadingSubjects(false);
    }
  };

  // Function: 복습 데이터 불러오기
  const loadReviews = async () => {
    try {
      setIsLoadingReviews(true);
      const data = await getReviewDocuments();
      setReviewData(data);
    } catch (error) {
      console.error('복습 데이터 조회 실패:', error);
    } finally {
      setIsLoadingReviews(false);
    }
  };

  // Effect: 주차 정보 업데이트
  useEffect(() => {
    updateWeekInfo();
  }, [weekStartDate]);

  // Function: 주차 정보 업데이트
  const updateWeekInfo = () => {
    const year = weekStartDate.getFullYear();
    const month = weekStartDate.getMonth() + 1;
    const weekOfMonth = Math.ceil(weekStartDate.getDate() / 7);
    setCurrentWeek(`${year}년 ${month}월 ${weekOfMonth}주차`);
  };

  // Handler: 주차 이전
  const handlePreviousWeek = () => {
    const newDate = new Date(weekStartDate);
    newDate.setDate(newDate.getDate() - 7);
    setWeekStartDate(newDate);
    setSelectedDate(null); // 주 변경 시 선택 해제
  };

  // Handler: 주차 다음
  const handleNextWeek = () => {
    const newDate = new Date(weekStartDate);
    newDate.setDate(newDate.getDate() + 7);
    setWeekStartDate(newDate);
    setSelectedDate(null); // 주 변경 시 선택 해제
  };

  // Handler: 날짜 클릭
  const handleDateClick = (dayIndex) => {
    const clickedDate = new Date(weekStartDate);
    clickedDate.setDate(clickedDate.getDate() + dayIndex);

    // 같은 날짜를 다시 클릭하면 선택 해제
    if (selectedDate && selectedDate.toDateString() === clickedDate.toDateString()) {
      setSelectedDate(null);
    } else {
      setSelectedDate(clickedDate);
    }
  };

  // Handler: 복습 항목 체크박스 토글
  const handleToggleReview = (id) => {
    console.log("Toggle review:", id);
  };

  // Handler: 과목 추가 모달 열기
  const handleAddSubject = () => {
    setShowAddSubjectModal(true);
  };

  // Handler: 과목 추가 제출
  const handleSubmitAddSubject = async (e) => {
    e.preventDefault();
    if (!newSubjectName.trim() || isAddingSubject) {
      return;
    }

    // 랜덤 색상 선택
    const colors = ["#E8E8FF", "#FFE8E8", "#E8FFE8", "#FFFFE8", "#FFE8FF", "#E8FFFF"];
    const randomColor = colors[Math.floor(Math.random() * colors.length)];

    try {
      setIsAddingSubject(true);
      await createSubject({
        name: newSubjectName.trim(),
        color: randomColor,
        description: "",
      });

      setNewSubjectName("");
      setShowAddSubjectModal(false);
      await loadSubjects();
    } catch (error) {
      console.error('과목 추가 실패:', error);
      alert('과목 추가에 실패했습니다. 다시 시도해주세요.');
    } finally {
      setIsAddingSubject(false);
    }
  };

  // Handler: 과목 카드 클릭
  const handleSubjectClick = (subject) => {
    console.log("Subject clicked:", subject);
    setSelectedSubject(subject);
  };

  // Handler: 과목 수정 모달 열기
  const handleEditSubject = (e, subject) => {
    e.stopPropagation();
    setEditingSubject(subject);
    setEditSubjectName(subject.name);
  };

  // Handler: 과목 수정 제출
  const handleSubmitEditSubject = async (e) => {
    e.preventDefault();
    if (!editSubjectName.trim() || editSubjectName.trim() === editingSubject.name || isUpdatingSubject) {
      return;
    }

    try {
      setIsUpdatingSubject(true);
      await updateSubject(editingSubject.subject_id, {
        name: editSubjectName.trim(),
      });

      setEditingSubject(null);
      setEditSubjectName("");
      await loadSubjects();
    } catch (error) {
      console.error('과목 수정 실패:', error);
      alert('과목 이름 수정에 실패했습니다. 다시 시도해주세요.');
    } finally {
      setIsUpdatingSubject(false);
    }
  };

  // Handler: 과목 삭제 (확인 없이 바로 삭제)
  const handleDeleteSubject = async (e, subject) => {
    e.stopPropagation();

    try {
      await deleteSubject(subject.subject_id);
      await loadSubjects();
    } catch (error) {
      console.error('과목 삭제 실패:', error);
    }
  };

  // Handler: 과목 상세에서 뒤로가기
  const handleBackToList = () => {
    setSelectedSubject(null);
  };

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

        {/* Today's Reviews Section: 오늘의 복습 섹션 */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-4">
            <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl">
              오늘의 복습
            </h2>
            <span className="w-8 h-8 flex items-center justify-center bg-[#00c288] text-white rounded-full [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-sm">
              {isLoadingReviews ? '...' : reviewData.today_count}
            </span>
          </div>

          {isLoadingReviews ? (
            <div className="flex flex-col gap-3">
              {Array.from({ length: 3 }).map((_, index) => (
                <ReviewItemSkeleton key={index} />
              ))}
            </div>
          ) : reviewData.today.length === 0 ? (
            <div className="bg-white rounded-2xl p-6 text-center">
              <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base">
                오늘 복습할 문서가 없습니다.
              </div>
            </div>
          ) : (
            <div className="flex flex-col gap-3">
              {reviewData.today.map((review) => (
                <div
                  key={review.document_id}
                  className="bg-white rounded-2xl p-6 flex items-center justify-between hover:shadow-md transition-shadow"
                >
                  <div className="flex items-center gap-4">
                    <div className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#111111] text-lg">
                      {review.subject_name}
                    </div>
                    <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base">
                      {review.title}
                    </div>
                    <button className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base hover:text-[#111111] transition-colors border-0 bg-transparent cursor-pointer">
                      →
                    </button>
                  </div>

                  <button
                    onClick={() => handleToggleReview(review.document_id)}
                    className="w-10 h-10 flex items-center justify-center rounded-full bg-white border-2 border-[#e0e0e0] border-0 cursor-pointer transition-colors hover:border-[#00c288]"
                  />
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Overdue Reviews Section: 밀린 복습 섹션 */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-4">
            <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl">
              밀린 복습
            </h2>
            <span className="w-8 h-8 flex items-center justify-center bg-[#ff6b6b] text-white rounded-full [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-sm">
              {isLoadingReviews ? '...' : reviewData.overdue_count}
            </span>
          </div>

          {isLoadingReviews ? (
            <div className="flex flex-col gap-3">
              {Array.from({ length: 2 }).map((_, index) => (
                <ReviewItemSkeleton key={index} />
              ))}
            </div>
          ) : reviewData.overdue.length === 0 ? (
            <div className="bg-white rounded-2xl p-6 text-center">
              <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base">
                밀린 복습이 없습니다.
              </div>
            </div>
          ) : (
            <div className="flex flex-col gap-3">
              {reviewData.overdue.map((review) => {
                // 밀린 일수 계산
                const createdDate = new Date(review.created_at);
                const today = new Date();
                const diffTime = Math.abs(today - createdDate);
                const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

                return (
                  <div
                    key={review.document_id}
                    className="bg-white rounded-2xl p-6 flex items-center justify-between hover:shadow-md transition-shadow"
                  >
                    <div className="flex items-center gap-4">
                      <div className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#111111] text-lg">
                        {review.subject_name}
                      </div>
                      <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base">
                        {review.title}
                      </div>
                      <button className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base hover:text-[#111111] transition-colors border-0 bg-transparent cursor-pointer">
                        →
                      </button>
                    </div>

                    <div className="flex items-center gap-4">
                      <span className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#ff6b6b] text-sm">
                        +{diffDays}일
                      </span>
                      <button
                        onClick={() => handleToggleReview(review.document_id)}
                        className="w-10 h-10 flex items-center justify-center rounded-full bg-white border-2 border-[#e0e0e0] border-0 cursor-pointer transition-colors hover:border-[#00c288]"
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* My Subjects Section: 내 과목 섹션 */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl">
              내 과목
            </h2>
            <button
              onClick={handleAddSubject}
              className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#00c288] text-base hover:opacity-70 transition-opacity border-0 bg-transparent cursor-pointer flex items-center gap-1"
            >
              + 과목 추가하기
            </button>
          </div>

          {isLoadingSubjects ? (
            <div className="grid grid-cols-2 gap-5">
              {Array.from({ length: 4 }).map((_, index) => (
                <CardSkeleton key={index} width="100%" height="165px" />
              ))}
            </div>
          ) : subjects.length === 0 ? (
            <div className="text-center py-12">
              <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base mb-4">
                아직 등록된 과목이 없습니다.
              </div>
              <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-sm">
                "+ 과목 추가하기" 버튼을 눌러 과목을 추가해보세요!
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-5">
              {subjects.map((subject) => (
                <div
                  key={subject.subject_id}
                  className="bg-white rounded-[32px] p-8 hover:shadow-lg transition-shadow cursor-pointer text-left relative group"
                  onClick={() => handleSubjectClick(subject)}
                >
                  {/* 수정/삭제 버튼 - 호버 시 표시 */}
                  <div className="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={(e) => handleEditSubject(e, subject)}
                      className="w-8 h-8 flex items-center justify-center rounded-full bg-[#00c288] hover:bg-[#00a876] text-white transition-colors border-0 cursor-pointer"
                      title="과목 이름 수정"
                    >
                      <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                        <path d="M11.333 2A2.121 2.121 0 0 1 14 4.667L5.333 13.333 1.667 14l.667-3.667L11 2Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    </button>
                    <button
                      onClick={(e) => handleDeleteSubject(e, subject)}
                      className="w-8 h-8 flex items-center justify-center rounded-full bg-[#ff6b6b] hover:bg-[#ff5252] text-white transition-colors border-0 cursor-pointer"
                      title="과목 삭제"
                    >
                      <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                        <path d="M2 4h12M5.333 4V2.667a1.333 1.333 0 0 1 1.334-1.334h2.666a1.333 1.333 0 0 1 1.334 1.334V4m2 0v9.333a1.333 1.333 0 0 1-1.334 1.334H4.667a1.333 1.333 0 0 1-1.334-1.334V4h9.334Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    </button>
                  </div>

                  <div className="flex items-start justify-between mb-6">
                    <div className={`w-16 h-16 rounded-2xl flex items-center justify-center`} style={{ backgroundColor: subject.color }}>
                      <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
                        <rect x="8" y="8" width="16" height="16" rx="2" stroke="#767676" strokeWidth="2"/>
                      </svg>
                    </div>
                  </div>

                  <div className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-xl mb-2">
                    {subject.name}
                  </div>

                  <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base">
                    페이퍼 {subject.total_documents || 0}장
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

      </div>

      {/* 과목 추가 모달 */}
      {showAddSubjectModal && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
          onClick={() => setShowAddSubjectModal(false)}
        >
          <div
            className="bg-white rounded-[32px] w-full max-w-[500px] p-8"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl mb-6">
              과목 추가하기
            </h2>
            <form onSubmit={handleSubmitAddSubject}>
              <input
                type="text"
                value={newSubjectName}
                onChange={(e) => setNewSubjectName(e.target.value)}
                placeholder="과목 이름을 입력하세요"
                className="w-full px-4 py-3 bg-[#f1f3f5] rounded-2xl [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#111111] text-base focus:outline-none focus:ring-2 focus:ring-[#00c288] border-0 mb-6"
                autoFocus
              />
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setShowAddSubjectModal(false)}
                  className="flex-1 h-12 bg-[#e0e0e0] rounded-2xl hover:bg-[#d0d0d0] transition-colors border-0 cursor-pointer [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#505050] text-base"
                >
                  취소
                </button>
                <button
                  type="submit"
                  disabled={isAddingSubject}
                  className={`flex-1 h-12 rounded-2xl transition-colors border-0 cursor-pointer [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-base ${
                    isAddingSubject
                      ? 'bg-[#e0e0e0] cursor-not-allowed text-[#999999]'
                      : 'bg-[#00c288] hover:bg-[#00a876] text-white'
                  }`}
                >
                  {isAddingSubject ? (
                    <div className="flex items-center justify-center gap-2">
                      <div className="w-4 h-4 border-2 border-[#999999] border-t-transparent rounded-full animate-spin"></div>
                      추가 중...
                    </div>
                  ) : (
                    '추가'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 과목 수정 모달 */}
      {editingSubject && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
          onClick={() => setEditingSubject(null)}
        >
          <div
            className="bg-white rounded-[32px] w-full max-w-[500px] p-8"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl mb-6">
              과목 이름 수정
            </h2>
            <form onSubmit={handleSubmitEditSubject}>
              <input
                type="text"
                value={editSubjectName}
                onChange={(e) => setEditSubjectName(e.target.value)}
                placeholder="과목 이름을 입력하세요"
                className="w-full px-4 py-3 bg-[#f1f3f5] rounded-2xl [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#111111] text-base focus:outline-none focus:ring-2 focus:ring-[#00c288] border-0 mb-6"
                autoFocus
              />
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setEditingSubject(null)}
                  className="flex-1 h-12 bg-[#e0e0e0] rounded-2xl hover:bg-[#d0d0d0] transition-colors border-0 cursor-pointer [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#505050] text-base"
                >
                  취소
                </button>
                <button
                  type="submit"
                  disabled={isUpdatingSubject}
                  className={`flex-1 h-12 rounded-2xl transition-colors border-0 cursor-pointer [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-base ${
                    isUpdatingSubject
                      ? 'bg-[#e0e0e0] cursor-not-allowed text-[#999999]'
                      : 'bg-[#00c288] hover:bg-[#00a876] text-white'
                  }`}
                >
                  {isUpdatingSubject ? (
                    <div className="flex items-center justify-center gap-2">
                      <div className="w-4 h-4 border-2 border-[#999999] border-t-transparent rounded-full animate-spin"></div>
                      수정 중...
                    </div>
                  ) : (
                    '수정'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
