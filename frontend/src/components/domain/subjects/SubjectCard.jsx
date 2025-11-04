/**
 * SubjectCard Component
 * 개별 과목 카드를 렌더링하는 컴포넌트
 */

import React from 'react';

export const SubjectCard = ({ subject, onSubjectClick, onEditSubject, onDeleteSubject }) => {
  return (
    <div
      className="bg-white rounded-[32px] p-8 hover:shadow-lg transition-shadow cursor-pointer text-left relative group"
      onClick={() => onSubjectClick(subject)}
    >
      {/* 수정/삭제 버튼 - 호버 시 표시 */}
      <div className="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
        <button
          onClick={(e) => onEditSubject(e, subject)}
          className="w-8 h-8 flex items-center justify-center rounded-full bg-[#00c288] hover:bg-[#00a876] text-white transition-colors border-0 cursor-pointer"
          title="과목 이름 수정"
        >
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path d="M11.333 2A2.121 2.121 0 0 1 14 4.667L5.333 13.333 1.667 14l.667-3.667L11 2Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
        <button
          onClick={(e) => onDeleteSubject(e, subject)}
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
  );
};