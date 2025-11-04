import React, { useState, useEffect } from "react";
import {
  IconCalendar,
  IconCheck,
  IconCheckCircle,
  IconCheveronDown,
  IconClipboardCheck,
  IconSearch
} from "../../../../components/ui/icons";
import { getReviewDocuments } from "../../../../services/subjectsApi";
import { getCurrentUser } from "../../../../services/authApi";
import { CardSkeleton, LargeCardSkeleton, UserGreetingSkeleton } from "../../../../components/ui/Skeleton";

export const DivWrapper = () => {
  // State: 검색어
  const [searchQuery, setSearchQuery] = useState('');

  // State: 사용자 정보
  const [userInfo, setUserInfo] = useState({
    name: '사용자', // 기본값
    email: '',
    // 추후 확장 가능한 필드들
    targetExam: '수능',
    targetDate: '2025-11-14' // 실제 수능일
  });
  const [isLoadingUser, setIsLoadingUser] = useState(true);

  // State: 복습 데이터
  const [reviewData, setReviewData] = useState({
    today: [],
    overdue: [],
    today_count: 0,
    overdue_count: 0
  });
  const [isLoadingReviews, setIsLoadingReviews] = useState(true);

  // State: 학습 통계 (추후 API로 대체 가능)
  const [studyStats, setStudyStats] = useState({
    reviewStreakRate: 82, // 복습 지속률
    isCalculated: false
  });

  // Handler: 검색 버튼 클릭
  const handleSearch = () => {
    console.log("Search clicked with query:", searchQuery);
    if (searchQuery.trim() === '') {
      alert("검색어를 입력해주세요.");
    } else {
      alert(`"${searchQuery}" 검색 결과를 표시합니다.`);
    }
  };

  // Handler: 검색어 입력 (엔터키 지원)
  const handleSearchKeyPress = (e) => {
    if (e.key === 'Enter') {
      handleSearch();
    }
  };

  // Handler: D-Day 드롭다운 클릭
  const handleDdayDropdown = () => {
    console.log("D-Day dropdown clicked");
    alert("D-Day 목록을 선택할 수 있습니다.");
  };

  // Handler: Today 카드 클릭
  const handleTodayCard = () => {
    console.log("Today card clicked");
    alert("오늘의 할 일 상세 페이지로 이동합니다.");
  };

  // Handler: 백지 복습 시작하기 버튼
  const handleStartReview = () => {
    console.log("백지 복습 시작하기 clicked");
    alert("백지 복습을 시작합니다.");
  };

  // Handler: 복습 이어하기 버튼
  const handleContinueReview = () => {
    console.log("복습 이어하기 clicked");
    alert("복습을 이어서 진행합니다.");
  };

  // Effect: 사용자 정보 로드
  useEffect(() => {
    const fetchUserData = async () => {
      try {
        setIsLoadingUser(true);
        const userData = await getCurrentUser();
        setUserInfo(prev => ({
          ...prev,
          name: userData.name || '사용자',
          email: userData.email || ''
        }));
      } catch (error) {
        console.error('Failed to fetch user data:', error);
        // 인증 에러 시 기본값 유지
      } finally {
        setIsLoadingUser(false);
      }
    };

    fetchUserData();
  }, []);

  // Effect: 복습 데이터 로드
  useEffect(() => {
    const fetchReviewData = async () => {
      try {
        setIsLoadingReviews(true);
        const data = await getReviewDocuments();
        setReviewData(data);
      } catch (error) {
        console.error('Failed to fetch review documents:', error);
        // 인증 에러나 API 에러 시 기본값으로 대체
        setReviewData({
          today: [],
          overdue: [],
          today_count: 0,
          overdue_count: 0
        });
      } finally {
        setIsLoadingReviews(false);
      }
    };

    fetchReviewData();
  }, []);

  // 총 복습 개수
  const totalReviews = reviewData.today_count + reviewData.overdue_count;

  // 유틸리티 함수들
  const formatCurrentDate = () => {
    const today = new Date();
    const year = today.getFullYear();
    const month = today.getMonth() + 1;
    const date = today.getDate();
    const dayNames = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    const dayName = dayNames[today.getDay()];

    return `${year}년 ${month}월 ${date}일  ${dayName}`;
  };

  const calculateDday = () => {
    const today = new Date();
    const targetDate = new Date(userInfo.targetDate);
    const diffTime = targetDate - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    return diffDays > 0 ? `${userInfo.targetExam} D-${diffDays}` : `${userInfo.targetExam} D+${Math.abs(diffDays)}`;
  };

  // Effect: 복습 지속률 계산 (한 번만 실행)
  useEffect(() => {
    if (!studyStats.isCalculated && !isLoadingReviews) {
      let streakRate;
      if (totalReviews === 0) {
        // 복습할 것이 없으면 높은 지속률 (75-95%)
        streakRate = Math.floor(Math.random() * 20) + 75;
      } else {
        // 복습할 것이 있으면 낮은 지속률 (60-80%)
        streakRate = Math.floor(Math.random() * 20) + 60;
      }

      setStudyStats({
        reviewStreakRate: streakRate,
        isCalculated: true
      });
    }
  }, [totalReviews, isLoadingReviews, studyStats.isCalculated]);

  return (
    <div className="flex-1 h-full bg-[#f1f3f5] rounded-[40px_0px_0px_40px] overflow-hidden flex items-start justify-center">
      <div className="relative w-full max-w-[1178px] main-content">
      {/* Search Bar: 검색창 */}
      <div className="absolute top-[60px] left-[60px] w-[526px] h-[60px] flex bg-white rounded-2xl overflow-hidden">
        <button
          onClick={handleSearch}
          className="w-[60px] h-[60px] flex items-center justify-center bg-[#00c288] rounded-2xl overflow-hidden cursor-pointer hover:bg-[#00a876] hover:shadow-lg active:scale-95 transition-all duration-200 border-0"
        >
          <IconSearch className="w-8 h-8 text-white" />
        </button>
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onKeyPress={handleSearchKeyPress}
          placeholder="검색어를 입력하세요..."
          className="flex-1 px-4 text-base [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#111111] outline-none border-0"
        />
      </div>

      {/* Stats Cards: 통계 카드들 */}
      <div className="inline-flex items-center gap-5 absolute top-[498px] left-[60px]">
        {isLoadingReviews || isLoadingUser ? (
          // 로딩 중 스켈레톤 표시
          <>
            <CardSkeleton width="255px" height="165px" />
            <CardSkeleton width="255px" height="165px" />
            <LargeCardSkeleton />
          </>
        ) : (
          <>
            {/* D-Day Card with Dropdown: D-Day 카드 (드롭다운) */}
            <div className="relative w-[255px] h-[165px] bg-white rounded-[32px] animate-fadeIn">
              <button
                onClick={handleDdayDropdown}
                className="inline-flex items-center gap-[100px] absolute top-8 left-8 cursor-pointer hover:bg-[#f8f9fa] hover:rounded-lg active:scale-95 transition-all duration-200 border-0 bg-transparent p-2 -m-2"
              >
                <div className="inline-flex items-center gap-1 relative flex-[0_0_auto]">
                  <IconCalendar className="w-5 h-5 text-[#00c288]" />
                  <div className="relative w-fit mt-[-1.00px] [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base tracking-[-0.40px] leading-[22.4px] whitespace-nowrap">
                    D-Day
                  </div>
                </div>

                <IconCheveronDown className="w-5 h-5" />
              </button>

              <div className="absolute top-[78px] left-8 [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl tracking-[-0.60px] leading-[33.6px] whitespace-nowrap">
                {calculateDday()}
              </div>
            </div>

            {/* Today Card: 오늘의 할 일 카드 */}
            <button
              onClick={handleTodayCard}
              className="relative w-[255px] h-[165px] bg-white rounded-[32px] cursor-pointer hover:shadow-xl hover:scale-[1.02] hover:-translate-y-1 active:scale-[0.98] transition-all duration-300 border-0 animate-fadeIn"
            >
              <div className="inline-flex items-end gap-1 absolute top-8 left-8">
                <IconCheckCircle className="w-5 h-5 text-[#00c288]" />
                <div className="relative w-fit mt-[-1.00px] [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base tracking-[-0.40px] leading-[22.4px] whitespace-nowrap">
                  Today
                </div>
              </div>

              <div className="absolute top-[78px] left-8 [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl tracking-[-0.60px] leading-[33.6px] whitespace-nowrap">
                {`${reviewData.today_count}개 할 일`}
              </div>

              <div className="absolute top-[116px] left-8 [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base tracking-[-0.40px] leading-[22.4px] whitespace-nowrap">
                {reviewData.overdue_count > 0
                  ? `${reviewData.overdue_count}개의 밀린 복습이 있어요`
                  : '밀린 복습이 없어요!'}
              </div>
            </button>

            {/* 오늘의 복습 카드 */}
            <div className="relative w-[508px] h-[165px] bg-white rounded-[32px] animate-fadeIn">
              <div className="inline-flex items-end gap-1 absolute top-8 left-8">
                <IconClipboardCheck className="w-6 h-6 text-[#00c288]" />
                <div className="relative w-fit mt-[-1.00px] [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base tracking-[-0.40px] leading-[22.4px] whitespace-nowrap">
                  오늘의 복습
                </div>
              </div>

              {reviewData.today.length === 0 ? (
                <div className="absolute top-[83px] left-8 [font-family:'Pretendard-Medium',Helvetica] font-medium text-[#767676] text-sm">
                  오늘 복습할 문서가 없어요!
                </div>
              ) : (
                <div className="absolute top-[70px] left-8 max-w-[340px] flex flex-col gap-2">
                  {reviewData.today.slice(0, 3).map((doc, index) => (
                    <div key={doc.document_id} className="flex items-center gap-2">
                      <div className="w-5 h-5 flex bg-sub-1 rounded-[100px] items-center justify-center">
                        <IconCheck className="w-3 h-3 text-white" />
                      </div>
                      <div className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-black text-sm tracking-[-0.35px] leading-[19.6px]">
                        {doc.subject_name}
                      </div>
                      <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-xs tracking-[-0.30px] leading-[16.8px] truncate max-w-[150px]">
                        - {doc.title}
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {reviewData.today.length > 0 && (
                <div className="absolute top-[71px] left-[calc(50.00%_+_87px)] w-[135px] h-[74px] flex flex-col">
                  {/* 복습 이어하기 버튼 */}
                  <button
                    onClick={handleContinueReview}
                    className="w-full h-[50px] flex bg-sub-1 rounded-[24px] shadow-[0px_2px_4px_#0000000a] cursor-pointer hover:bg-[#00a876] hover:shadow-lg active:scale-95 transition-all duration-200 border-0 items-center justify-center"
                  >
                    <div className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-white text-sm tracking-[-0.35px] leading-[19.6px] whitespace-nowrap">
                      복습 이어하기
                    </div>
                  </button>

                  {/* 진도율 바 */}
                  <div className="mt-2 w-full">
                    <div className="flex justify-between items-center mb-1">
                      <span className="text-xs text-[#767676] [font-family:'Pretendard-Regular',Helvetica]">진도율</span>
                      <span className="text-xs text-[#00c288] font-semibold [font-family:'Pretendard-SemiBold',Helvetica]">
                        {Math.round((3 - reviewData.today.length) / 3 * 100)}%
                      </span>
                    </div>
                    <div className="w-full bg-[#f1f3f5] rounded-full h-1.5">
                      <div
                        className="bg-[#00c288] h-1.5 rounded-full transition-all duration-300"
                        style={{ width: `${Math.round((3 - reviewData.today.length) / 3 * 100)}%` }}
                      />
                    </div>
                  </div>
                </div>
              )}
            </div>
          </>
        )}
      </div>

      <div className="absolute top-[76px] left-[917px] [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-xl tracking-[-0.50px] leading-[28.0px] whitespace-nowrap">
        {formatCurrentDate()}
      </div>

      {isLoadingUser || isLoadingReviews ? (
        // 사용자 인사말 스켈레톤
        <div className="absolute top-40 left-[60px] w-[1058px] h-[298px]">
          <UserGreetingSkeleton />
        </div>
      ) : (
        <div className="absolute top-40 left-[60px] w-[1058px] h-[298px] flex flex-col bg-white rounded-[40px] overflow-hidden animate-fadeIn">
          <div className="ml-[42px] w-[238px] h-[45px] mt-[60px] [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-black text-[32px] tracking-[-0.80px] leading-[44.8px] whitespace-nowrap">
            안녕하세요, {userInfo.name}님!
          </div>

          <div className="flex ml-[42px] w-[505px] h-[60px] relative mt-3 flex-col items-start gap-1">
            <p className="relative w-[528px] mt-[-1.00px] mr-[-23.00px] [font-family:'Pretendard-Medium',Helvetica] font-medium text-[#767676] text-xl tracking-[-0.50px] leading-[28.0px]">
              {totalReviews > 0
                ? `오늘 ${reviewData.today_count}개, 밀린 복습 ${reviewData.overdue_count}개가 있어요! 오늘도 화이팅!`
                : `최근 7일 간 복습 지속률이 ${studyStats.reviewStreakRate}%예요! 이번주도 정말 잘 하고 있어요`}
            </p>

            <div className="relative self-stretch [font-family:'Pretendard-Medium',Helvetica] font-medium text-[#767676] text-xl tracking-[-0.50px] leading-[28.0px]">
              {totalReviews > 0 ? '복습 시작해볼까요?' : '오후 공부 시작해볼까요?'}
            </div>
          </div>

          <button
            onClick={handleStartReview}
            className="ml-[-783px] h-[62px] w-[195px] self-center mt-[19px] flex bg-sub-1 rounded-[32px] shadow-[0px_2px_4px_#0000000a] cursor-pointer hover:bg-[#00a876] hover:shadow-lg active:scale-95 transition-all duration-200 border-0"
          >
            <div className="inline-flex mt-5 w-[139px] h-[22px] ml-7 relative items-center gap-1">
              <IconClipboardCheck className="w-5 h-5 text-white" />
              <div className="relative w-fit mt-[-1.00px] [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-white text-base tracking-[-0.40px] leading-[22.4px] whitespace-nowrap">
                백지 복습 시작하기
              </div>

              <div className="absolute top-1 left-[13px] w-1.5 h-1.5 bg-second rounded-[3px]" />
            </div>
          </button>
        </div>
      )}

      <img
        className="absolute top-[91px] left-[676px] w-[442px] h-[409px] aspect-[1.13] object-cover"
        alt="Image"
        src="https://c.animaapp.com/acBhPnRI/img/image-16@2x.png"
      />
      </div>
    </div>
  );
};
