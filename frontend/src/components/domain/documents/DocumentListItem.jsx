/**
 * DocumentListItem Component
 * 문서 목록 아이템 컴포넌트
 */

import React from 'react';
import { formatDateWithDots } from '../../../lib/utils';

/**
 * 문서 리스트 아이템
 * @param {Object} props
 * @param {Object} props.document - 문서 객체
 * @param {Function} props.onClick - 클릭 핸들러
 * @param {Function} props.onEdit - 수정 핸들러
 * @param {Function} props.onDelete - 삭제 핸들러
 * @param {boolean} props.isDeleting - 삭제 중 여부
 */
export const DocumentListItem = ({
  document,
  onClick,
  onEdit,
  onDelete,
  isDeleting = false,
}) => {
  const formattedDate = formatDateWithDots(document.created_at);

  return (
    <div
      className="w-full bg-white rounded-2xl p-6 flex items-center justify-between hover:shadow-xl hover:-translate-y-1 transition-all duration-300 cursor-pointer relative group"
      onClick={onClick}
    >
      {/* Left: 문서 아이콘 */}
      <div className="flex items-center gap-4">
        <div className="w-14 h-14 flex items-center justify-center bg-[#f1f3f5] rounded-xl">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path
              d="M14 2H6C5.46957 2 4.96086 2.21071 4.58579 2.58579C4.21071 2.96086 4 3.46957 4 4V20C4 20.5304 4.21071 21.0391 4.58579 21.4142C4.96086 21.7893 5.46957 22 6 22H18C18.5304 22 19.0391 21.7893 19.4142 21.4142C19.7893 21.0391 20 20.5304 20 20V8L14 2Z"
              stroke="#767676"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path d="M14 2V8H20" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>

        {/* Center: 제목과 메타정보 */}
        <div className="flex flex-col items-start gap-1">
          <div className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-lg text-left">
            {document.title}
          </div>
          <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm flex items-center gap-2">
            <span>생성과제 {document.pages || 1}장</span>
            <span>•</span>
            <span>{formattedDate}</span>
          </div>
        </div>
      </div>

      {/* Right: 수정/삭제 버튼 및 화살표 */}
      <div className="flex items-center gap-2">
        {/* 수정/삭제 버튼 - 호버 시 표시 */}
        <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-all duration-300">
          <button
            onClick={onEdit}
            className="w-8 h-8 flex items-center justify-center rounded-full bg-blue-500 hover:bg-blue-600 hover:scale-110 active:scale-95 text-white transition-all duration-200 border-0 cursor-pointer"
            title="문서 제목 수정"
          >
            <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
              <path
                d="M11.333 2A2.121 2.121 0 0 1 14 4.667L5.333 13.333 1.667 14l.667-3.667L11 2Z"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
          <button
            onClick={onDelete}
            disabled={isDeleting}
            className={`w-8 h-8 flex items-center justify-center rounded-full text-white transition-all duration-200 border-0 cursor-pointer ${
              isDeleting
                ? 'bg-[#cccccc] cursor-not-allowed'
                : 'bg-red-500 hover:bg-red-600 hover:scale-110 active:scale-95'
            }`}
            title="문서 삭제"
          >
            {isDeleting ? (
              <div className="w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
            ) : (
              <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
                <path
                  d="M2 4h12M5.333 4V2.667a1.333 1.333 0 0 1 1.334-1.334h2.666a1.333 1.333 0 0 1 1.334 1.334V4m2 0v9.333a1.333 1.333 0 0 1-1.334 1.334H4.667a1.333 1.333 0 0 1-1.334-1.334V4h9.334Z"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            )}
          </button>
        </div>

        {/* 화살표 아이콘 */}
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
          <path d="M9 18L15 12L9 6" stroke="#999999" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
    </div>
  );
};
