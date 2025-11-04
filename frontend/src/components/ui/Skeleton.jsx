/**
 * Skeleton Component
 * 로딩 중 스켈레톤 UI를 제공하는 컴포넌트
 */

import React from 'react';

// 기본 스켈레톤 컴포넌트
export const Skeleton = ({ className = '', width, height, rounded = true }) => {
  return (
    <div
      className={`skeleton-shimmer ${rounded ? 'rounded-xl' : ''} ${className}`}
      style={{
        width: width || '100%',
        height: height || '20px'
      }}
    />
  );
};

// 카드 스켈레톤 컴포넌트
export const CardSkeleton = ({ width = '255px', height = '165px' }) => {
  return (
    <div
      className="bg-white rounded-[32px] p-8 shadow-sm animate-pulse"
      style={{ width, height }}
    >
      {/* 아이콘 + 제목 영역 */}
      <div className="flex items-center gap-2 mb-4">
        <Skeleton width="20px" height="20px" className="rounded-full" />
        <Skeleton width="60px" height="16px" />
      </div>

      {/* 메인 텍스트 영역 */}
      <Skeleton width="80%" height="32px" className="mb-2" />

      {/* 서브 텍스트 영역 */}
      <Skeleton width="60%" height="16px" />
    </div>
  );
};

// 큰 카드 스켈레톤 (오늘의 복습용)
export const LargeCardSkeleton = () => {
  return (
    <div className="bg-white rounded-[32px] p-8 shadow-sm animate-pulse w-[508px] h-[165px]">
      {/* 아이콘 + 제목 영역 */}
      <div className="flex items-center gap-2 mb-4">
        <Skeleton width="24px" height="24px" className="rounded-full" />
        <Skeleton width="80px" height="16px" />
      </div>

      {/* 복습 리스트 영역 */}
      <div className="flex justify-between">
        <div className="flex flex-col gap-2 flex-1">
          {[1, 2, 3].map((item) => (
            <div key={item} className="flex items-center gap-2">
              <Skeleton width="20px" height="20px" className="rounded-full" />
              <Skeleton width="100px" height="14px" />
              <Skeleton width="80px" height="14px" />
            </div>
          ))}
        </div>

        {/* 버튼 영역 */}
        <div className="flex flex-col">
          <Skeleton width="135px" height="50px" className="mb-2" />
          <Skeleton width="135px" height="16px" />
        </div>
      </div>
    </div>
  );
};

// 리스트 아이템 스켈레톤
export const ListItemSkeleton = () => {
  return (
    <div className="flex items-center gap-3 p-3 animate-pulse">
      <Skeleton width="20px" height="20px" className="rounded-full" />
      <div className="flex-1">
        <Skeleton width="120px" height="16px" className="mb-1" />
        <Skeleton width="80px" height="14px" />
      </div>
      <Skeleton width="60px" height="14px" />
    </div>
  );
};

// 사용자 인사말 스켈레톤
export const UserGreetingSkeleton = () => {
  return (
    <div className="bg-white rounded-[40px] p-[42px] animate-pulse">
      {/* 인사말 */}
      <Skeleton width="240px" height="45px" className="mb-4" />

      {/* 설명 텍스트 */}
      <div className="space-y-2 mb-6">
        <Skeleton width="500px" height="20px" />
        <Skeleton width="300px" height="20px" />
      </div>

      {/* 버튼 */}
      <div className="flex justify-center">
        <Skeleton width="195px" height="62px" />
      </div>
    </div>
  );
};

// 복습 섹션 스켈레톤
export const ReviewSectionSkeleton = ({ title, count = 3 }) => {
  return (
    <div className="mb-8">
      {/* 제목 + 카운트 */}
      <div className="flex items-center gap-3 mb-4">
        <Skeleton width="120px" height="32px" />
        <Skeleton width="32px" height="32px" className="rounded-full" />
      </div>

      {/* 리뷰 아이템들 */}
      <div className="flex flex-col gap-3">
        {Array.from({ length: count }).map((_, index) => (
          <ReviewItemSkeleton key={index} />
        ))}
      </div>
    </div>
  );
};

// 복습 아이템 스켈레톤
export const ReviewItemSkeleton = () => {
  return (
    <div className="bg-white rounded-2xl p-6 flex items-center justify-between animate-pulse">
      <div className="flex items-center gap-4 flex-1">
        <Skeleton width="80px" height="20px" />
        <Skeleton width="150px" height="16px" />
        <Skeleton width="20px" height="16px" />
      </div>

      <div className="flex items-center gap-4">
        <Skeleton width="40px" height="16px" />
        <Skeleton width="40px" height="40px" className="rounded-full" />
      </div>
    </div>
  );
};