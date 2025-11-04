/**
 * SubjectsList Component
 * 내 과목 섹션을 담당하는 컴포넌트
 */

import React from 'react';
import { SubjectCard } from './SubjectCard';

export const SubjectsList = ({
  subjects,
  isLoading,
  onAddSubject,
  onSubjectClick,
  onEditSubject,
  onDeleteSubject
}) => {
  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl">
          내 과목
        </h2>
        <button
          onClick={onAddSubject}
          className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#00c288] text-base hover:opacity-70 transition-opacity border-0 bg-transparent cursor-pointer flex items-center gap-1"
        >
          + 과목 추가하기
        </button>
      </div>

      {isLoading ? (
        <div className="text-center py-12">
          <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base">
            과목 목록을 불러오는 중...
          </div>
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
            <SubjectCard
              key={subject.subject_id}
              subject={subject}
              onSubjectClick={onSubjectClick}
              onEditSubject={onEditSubject}
              onDeleteSubject={onDeleteSubject}
            />
          ))}
        </div>
      )}
    </div>
  );
};