/**
 * TodayReviews Component
 * 오늘의 복습 섹션을 담당하는 컴포넌트
 */

import React from 'react';
import { ReviewItemSkeleton } from '../../ui/Skeleton';

export const TodayReviews = ({ reviewData, isLoading, onToggleReview }) => {
  return (
    <div className="mb-8">
      <div className="flex items-center gap-3 mb-4">
        <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl">
          오늘의 복습
        </h2>
        <span className="w-8 h-8 flex items-center justify-center bg-[#00c288] text-white rounded-full [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-sm">
          {isLoading ? '...' : reviewData.today_count}
        </span>
      </div>

      {isLoading ? (
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
                onClick={() => onToggleReview(review.document_id)}
                className="w-10 h-10 flex items-center justify-center rounded-full bg-white border-2 border-[#e0e0e0] border-0 cursor-pointer transition-colors hover:border-[#00c288]"
              />
            </div>
          ))}
        </div>
      )}
    </div>
  );
};