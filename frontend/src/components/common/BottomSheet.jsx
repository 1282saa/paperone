/**
 * BottomSheet Component
 * 하단에서 올라오는 모달 컴포넌트
 */

import React from 'react';

/**
 * 바텀시트 컴포넌트
 * @param {Object} props
 * @param {boolean} props.isOpen - 열림 여부
 * @param {Function} props.onClose - 닫기 핸들러
 * @param {string} props.title - 제목
 * @param {React.ReactNode} props.children - 자식 컴포넌트
 */
export const BottomSheet = ({ isOpen, onClose, title, children }) => {
  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-end justify-center z-50 animate-fade-in"
      onClick={onClose}
    >
      <div
        className="bg-white rounded-t-[32px] w-full max-w-[600px] p-8 animate-slide-up"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Handle bar: 상단 바 */}
        <div className="w-12 h-1 bg-[#e0e0e0] rounded-full mx-auto mb-8" />

        {/* Title: 제목 */}
        {title && (
          <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl text-center mb-8">
            {title}
          </h2>
        )}

        {/* Content: 내용 */}
        {children}
      </div>
    </div>
  );
};

/**
 * 바텀시트 옵션 아이템
 * @param {Object} props
 * @param {Function} props.onClick - 클릭 핸들러
 * @param {React.ReactNode} props.icon - 아이콘
 * @param {string} props.title - 제목
 * @param {string} props.description - 설명
 */
export const BottomSheetOption = ({ onClick, icon, title, description }) => {
  return (
    <button
      onClick={onClick}
      className="flex items-center gap-4 p-6 bg-[#f1f3f5] rounded-2xl hover:bg-[#e8eaed] hover:scale-[1.02] active:scale-[0.98] transition-all duration-200 border-0 cursor-pointer w-full"
    >
      <div className="w-14 h-14 flex items-center justify-center bg-[#00c288] rounded-xl">
        {icon}
      </div>

      <div className="flex flex-col items-start flex-1">
        <span className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-lg">
          {title}
        </span>
        <span className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-sm">
          {description}
        </span>
      </div>

      <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
        <path d="M9 18L15 12L9 6" stroke="#999999" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    </button>
  );
};
