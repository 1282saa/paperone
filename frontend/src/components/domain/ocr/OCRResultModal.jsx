/**
 * OCRResultModal Component
 * OCR 결과 표시 모달 (좌우 분할)
 */

import React, { useState } from 'react';

/**
 * OCR 결과 모달
 * @param {Object} props
 * @param {boolean} props.isOpen - 열림 여부
 * @param {Function} props.onClose - 닫기 핸들러
 * @param {Function} props.onSave - 저장 핸들러
 * @param {Object} props.ocrResult - OCR 결과 객체
 * @param {File} props.imageFile - 원본 이미지 파일
 * @param {string} props.editableText - 편집 가능한 텍스트
 * @param {Function} props.onTextChange - 텍스트 변경 핸들러
 * @param {boolean} props.isSaving - 저장 중 여부
 */
export const OCRResultModal = ({
  isOpen,
  onClose,
  onSave,
  ocrResult,
  imageFile,
  editableText,
  onTextChange,
  isSaving = false,
}) => {
  const [isFullscreen, setIsFullscreen] = useState(false);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 animate-fade-in"
      onClick={onClose}
    >
      <div
        className={`bg-white rounded-[32px] flex flex-col animate-scale-in ${
          isFullscreen ? 'w-[95vw] h-[95vh]' : 'w-full max-w-[1200px] h-[80vh]'
        } transition-all duration-300`}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header: 모달 헤더 */}
        <div className="flex items-center justify-between p-6 border-b border-[#f1f3f5]">
          <div className="flex items-center gap-4">
            <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl">
              추출된 텍스트
            </h2>
            {ocrResult && (
              <div className="flex items-center gap-4 px-4 py-2 bg-[#f1f3f5] rounded-xl">
                <div className="flex items-center gap-2">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
                    <path
                      d="M10 18C14.4183 18 18 14.4183 18 10C18 5.58172 14.4183 2 10 2C5.58172 2 2 5.58172 2 10C2 14.4183 5.58172 18 10 18Z"
                      stroke="#00c288"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                    <path
                      d="M10 6V10L12 12"
                      stroke="#00c288"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                  <span className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#111111] text-sm">
                    신뢰도: {ocrResult.confidence}%
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
                    <path
                      d="M6 2V6M14 2V6M3 10H17M5 4H15C16.1046 4 17 4.89543 17 6V16C17 17.1046 16.1046 18 15 18H5C3.89543 18 3 17.1046 3 16V6C3 4.89543 3.89543 4 5 4Z"
                      stroke="#00c288"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                  <span className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#111111] text-sm">
                    {ocrResult.lines.length}개 라인
                  </span>
                </div>
              </div>
            )}
          </div>

          <div className="flex items-center gap-2">
            {/* 전체화면 토글 버튼 */}
            <button
              onClick={() => setIsFullscreen(!isFullscreen)}
              className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-[#f1f3f5] transition-colors border-0 bg-transparent cursor-pointer"
              title={isFullscreen ? '작게 보기' : '전체화면'}
            >
              {isFullscreen ? (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                  <path
                    d="M8 3V5H5V8H3V5C3 3.89543 3.89543 3 5 3H8ZM21 8V5C21 3.89543 20.1046 3 19 3H16V5H19V8H21ZM16 21V19H19V16H21V19C21 20.1046 20.1046 21 19 21H16ZM5 19V16H3V19C3 20.1046 3.89543 21 5 21H8V19H5Z"
                    fill="#767676"
                  />
                </svg>
              ) : (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                  <path
                    d="M3 3H9V5H5V9H3V3ZM21 3V9H19V5H15V3H21ZM21 21H15V19H19V15H21V21ZM3 21V15H5V19H9V21H3Z"
                    fill="#767676"
                  />
                </svg>
              )}
            </button>

            {/* 닫기 버튼 */}
            <button
              onClick={onClose}
              className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-[#f1f3f5] transition-colors border-0 bg-transparent cursor-pointer"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path
                  d="M18 6L6 18M6 6L18 18"
                  stroke="#767676"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </button>
          </div>
        </div>

        {/* Content: 좌우 분할 영역 */}
        <div className="flex-1 flex overflow-hidden">
          {/* Left Panel: 원본 이미지 */}
          <div className="w-1/2 p-6 border-r border-[#f1f3f5] flex flex-col">
            <div className="flex items-center gap-2 mb-4">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                <path
                  d="M21 19V5C21 3.89543 20.1046 3 19 3H5C3.89543 3 3 3.89543 3 5V19C3 20.1046 3.89543 21 5 21H19C20.1046 21 19 20.1046 21 19Z"
                  stroke="#00c288"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
                <path
                  d="M8.5 10C9.32843 10 10 9.32843 10 8.5C10 7.67157 9.32843 7 8.5 7C7.67157 7 7 7.67157 7 8.5C7 9.32843 7.67157 10 8.5 10Z"
                  stroke="#00c288"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
                <path
                  d="M21 15L16 10L5 21"
                  stroke="#00c288"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
              <h3 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-lg">
                원본 이미지
              </h3>
            </div>

            <div className="flex-1 bg-[#f8f9fa] rounded-2xl p-4 flex items-center justify-center overflow-hidden">
              {imageFile ? (
                <img
                  src={URL.createObjectURL(imageFile)}
                  alt="업로드된 이미지"
                  className="max-w-full max-h-full object-contain rounded-xl shadow-lg"
                />
              ) : (
                <div className="text-center">
                  <svg width="64" height="64" viewBox="0 0 24 24" fill="none" className="mx-auto mb-4">
                    <path
                      d="M21 19V5C21 3.89543 20.1046 3 19 3H5C3.89543 3 3 3.89543 3 5V19C3 20.1046 3.89543 21 5 21H19C20.1046 21 19 20.1046 21 19Z"
                      stroke="#cccccc"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                    <path
                      d="M8.5 10C9.32843 10 10 9.32843 10 8.5C10 7.67157 9.32843 7 8.5 7C7.67157 7 7 7.67157 7 8.5C7 9.32843 7.67157 10 8.5 10Z"
                      stroke="#cccccc"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                    <path
                      d="M21 15L16 10L5 21"
                      stroke="#cccccc"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                  <p className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-base">
                    이미지를 불러올 수 없습니다
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Right Panel: 추출된 텍스트 */}
          <div className="w-1/2 p-6 flex flex-col">
            <div className="flex items-center gap-2 mb-4">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                <path
                  d="M14 2H6C5.46957 2 4.96086 2.21071 4.58579 2.58579C4.21071 2.96086 4 3.46957 4 4V20C4 20.5304 4.21071 21.0391 4.58579 21.4142C4.96086 21.7893 5.46957 22 6 22H18C18.5304 22 19.0391 21.7893 19.4142 21.4142C19.7893 21.0391 20 20.5304 20 20V8L14 2Z"
                  stroke="#00c288"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
                <path d="M14 2V8H20" stroke="#00c288" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
              <h3 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-lg">
                추출된 텍스트
              </h3>
            </div>

            <div className="flex-1 overflow-hidden">
              <textarea
                value={editableText}
                onChange={(e) => onTextChange(e.target.value)}
                className="w-full h-full p-4 bg-[#f8f9fa] rounded-2xl [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#111111] text-base resize-none focus:outline-none focus:ring-2 focus:ring-[#00c288] border-0 leading-relaxed"
                placeholder="추출된 텍스트가 여기에 표시됩니다..."
              />
            </div>
          </div>
        </div>

        {/* Footer: 액션 버튼들 */}
        <div className="flex items-center gap-4 p-6 border-t border-[#f1f3f5]">
          <button
            onClick={onClose}
            className="flex-1 h-14 flex items-center justify-center bg-[#e0e0e0] rounded-2xl hover:bg-[#d0d0d0] active:scale-95 transition-all duration-200 border-0 cursor-pointer"
          >
            <span className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#505050] text-base">
              취소
            </span>
          </button>
          <button
            onClick={onSave}
            disabled={isSaving}
            className={`flex-1 h-14 flex items-center justify-center rounded-2xl transition-all duration-200 border-0 cursor-pointer ${
              isSaving ? 'bg-[#e0e0e0] cursor-not-allowed' : 'bg-[#00c288] hover:bg-[#00a876] active:scale-95'
            }`}
          >
            {isSaving ? (
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 border-2 border-[#999999] border-t-transparent rounded-full animate-spin"></div>
                <span className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#999999] text-base">
                  저장 중...
                </span>
              </div>
            ) : (
              <span className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-white text-base">
                저장하기
              </span>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
