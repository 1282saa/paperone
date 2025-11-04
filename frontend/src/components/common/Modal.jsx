/**
 * Modal Component
 * 재사용 가능한 모달 컴포넌트
 */

import React from 'react';

export const Modal = ({
  isOpen,
  onClose,
  title,
  children,
  className = ""
}) => {
  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      onClick={onClose}
    >
      <div
        className={`bg-white rounded-[32px] w-full max-w-[500px] p-8 ${className}`}
        onClick={(e) => e.stopPropagation()}
      >
        {title && (
          <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl mb-6">
            {title}
          </h2>
        )}
        {children}
      </div>
    </div>
  );
};