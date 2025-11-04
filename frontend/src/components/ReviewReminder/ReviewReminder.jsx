import React, { useState, useEffect } from 'react';

export const ReviewReminder = ({ documents = [] }) => {
  const [urgentReviews, setUrgentReviews] = useState([]);
  const [todayReviews, setTodayReviews] = useState([]);
  const [upcomingReviews, setUpcomingReviews] = useState([]);

  useEffect(() => {
    const now = new Date();
    const urgent = [];
    const today = [];
    const upcoming = [];

    documents.forEach(doc => {
      if (!doc.last_review_date) {
        const createdDate = new Date(doc.created_at);
        const daysSinceCreation = Math.floor((now - createdDate) / (1000 * 60 * 60 * 24));

        if (daysSinceCreation >= 1) {
          urgent.push({
            ...doc,
            memoryRate: calculateMemoryRate(daysSinceCreation),
            daysOverdue: daysSinceCreation
          });
        }
      } else {
        const lastReviewDate = new Date(doc.last_review_date);
        const daysSinceReview = Math.floor((now - lastReviewDate) / (1000 * 60 * 60 * 24));
        const nextReviewDay = getNextReviewInterval(doc.review_count || 1);

        if (daysSinceReview > nextReviewDay) {
          urgent.push({
            ...doc,
            memoryRate: calculateMemoryRate(daysSinceReview),
            daysOverdue: daysSinceReview - nextReviewDay
          });
        } else if (daysSinceReview === nextReviewDay) {
          today.push({
            ...doc,
            memoryRate: calculateMemoryRate(daysSinceReview)
          });
        } else {
          upcoming.push({
            ...doc,
            daysUntilReview: nextReviewDay - daysSinceReview
          });
        }
      }
    });

    urgent.sort((a, b) => a.memoryRate - b.memoryRate);

    setUrgentReviews(urgent);
    setTodayReviews(today);
    setUpcomingReviews(upcoming);
  }, [documents]);

  const calculateMemoryRate = (days) => {
    if (days === 0) return 100;
    if (days === 1) return 58;
    if (days === 2) return 44;
    if (days === 7) return 33;
    if (days === 14) return 28;
    if (days === 30) return 21;
    return Math.max(20, Math.round(100 * Math.exp(-days / 5)));
  };

  const getNextReviewInterval = (reviewCount) => {
    const intervals = [1, 3, 7, 14, 30, 60];
    return intervals[Math.min(reviewCount - 1, intervals.length - 1)];
  };

  const totalReviews = urgentReviews.length + todayReviews.length;

  if (totalReviews === 0 && upcomingReviews.length === 0) {
    return null;
  }

  return (
    <div className="space-y-4">
      {/* 긴급 복습 */}
      {urgentReviews.length > 0 && (
        <div className="bg-red-50 border border-red-200 rounded-xl p-6">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                <h3 className="text-base font-semibold text-[#111111]">
                  복습 필요
                </h3>
                <span className="px-2 py-0.5 bg-red-500 text-white text-xs rounded-full font-medium">
                  {urgentReviews.length}
                </span>
              </div>

              <div className="mb-3">
                <p className="text-sm text-[#111111] font-medium mb-2">
                  {urgentReviews[0].title}
                </p>
                <div className="flex items-center gap-3">
                  <div className="flex-1 h-1.5 bg-red-200 rounded-full overflow-hidden max-w-[120px]">
                    <div
                      className="h-full bg-red-500 transition-all"
                      style={{ width: `${100 - urgentReviews[0].memoryRate}%` }}
                    />
                  </div>
                  <span className="text-xs font-medium text-red-700">
                    {urgentReviews[0].memoryRate}%
                  </span>
                  <span className="text-xs text-red-600">
                    {urgentReviews[0].daysOverdue}일 경과
                  </span>
                </div>
              </div>

              {urgentReviews.length > 1 && (
                <p className="text-xs text-red-600">
                  외 {urgentReviews.length - 1}건
                </p>
              )}
            </div>

            <button className="px-5 py-2.5 bg-red-500 text-white rounded-xl text-sm font-medium hover:bg-red-600 transition-colors">
              복습하기
            </button>
          </div>
        </div>
      )}

      {/* 오늘의 복습 */}
      {todayReviews.length > 0 && (
        <div className="bg-blue-50 border border-blue-200 rounded-xl p-6">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-6 h-6 flex items-center justify-center bg-blue-500 rounded-lg">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
                <h3 className="text-base font-semibold text-[#111111]">
                  오늘 복습
                </h3>
                <span className="px-2 py-0.5 bg-blue-500 text-white text-xs rounded-full font-medium">
                  {todayReviews.length}
                </span>
              </div>

              <div className="space-y-2">
                {todayReviews.slice(0, 2).map((doc, idx) => (
                  <div key={idx} className="flex items-center justify-between bg-white rounded-lg px-3 py-2">
                    <span className="text-sm font-medium text-[#111111]">
                      {doc.title}
                    </span>
                    <span className="text-xs text-[#767676]">
                      {doc.memoryRate}%
                    </span>
                  </div>
                ))}
                {todayReviews.length > 2 && (
                  <p className="text-xs text-blue-600 pl-3">
                    외 {todayReviews.length - 2}건
                  </p>
                )}
              </div>
            </div>

            <button className="px-5 py-2.5 bg-blue-500 text-white rounded-xl text-sm font-medium hover:bg-blue-600 transition-colors">
              복습하기
            </button>
          </div>
        </div>
      )}

      {/* 예정된 복습 */}
      {upcomingReviews.length > 0 && (
        <details className="bg-[#f8f9fa] rounded-xl p-6">
          <summary className="flex items-center justify-between cursor-pointer">
            <div className="flex items-center gap-2">
              <div className="w-6 h-6 flex items-center justify-center bg-[#767676] rounded-lg">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                  <rect x="3" y="4" width="18" height="18" rx="2" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <line x1="16" y1="2" x2="16" y2="6" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <line x1="8" y1="2" x2="8" y2="6" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <line x1="3" y1="10" x2="21" y2="10" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <h3 className="text-base font-medium text-[#111111]">
                예정
              </h3>
              <span className="px-2 py-0.5 bg-[#e0e0e0] text-[#767676] text-xs rounded-full">
                {upcomingReviews.length}
              </span>
            </div>
          </summary>

          <div className="mt-4 space-y-2">
            {upcomingReviews.map((doc, idx) => (
              <div key={idx} className="flex items-center justify-between bg-white rounded-lg px-4 py-3">
                <span className="text-sm font-medium text-[#111111]">{doc.title}</span>
                <span className="text-xs text-[#767676]">
                  {doc.daysUntilReview}일 후
                </span>
              </div>
            ))}
          </div>
        </details>
      )}

      {/* 통계 */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-white rounded-xl p-4 text-center border border-[#f0f0f0]">
          <div className="text-2xl font-bold text-red-500">{urgentReviews.length}</div>
          <div className="text-xs text-[#767676]">긴급</div>
        </div>
        <div className="bg-white rounded-xl p-4 text-center border border-[#f0f0f0]">
          <div className="text-2xl font-bold text-blue-500">{todayReviews.length}</div>
          <div className="text-xs text-[#767676]">오늘</div>
        </div>
        <div className="bg-white rounded-xl p-4 text-center border border-[#f0f0f0]">
          <div className="text-2xl font-bold text-[#767676]">{upcomingReviews.length}</div>
          <div className="text-xs text-[#767676]">예정</div>
        </div>
      </div>
    </div>
  );
};
