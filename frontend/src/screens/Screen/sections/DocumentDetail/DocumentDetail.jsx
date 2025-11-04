import React, { useState, useEffect } from "react";
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import MDEditor from '@uiw/react-md-editor';
import '@uiw/react-md-editor/markdown-editor.css';
import '@uiw/react-markdown-preview/markdown.css';
import { getDocumentDetail, updateDocument, aiTextCorrection } from "../../../../services/subjectsApi";
import { Skeleton } from "../../../../components/ui/Skeleton";
import { ReviewMode } from "../../../../components/ReviewMode/ReviewMode";
import { ForgettingCurve } from "../../../../components/ForgettingCurve/ForgettingCurve";

export const DocumentDetail = ({ documentId, onBack }) => {
  // State: 문서 데이터
  const [document, setDocument] = useState(null);

  // State: 로딩 상태
  const [isLoading, setIsLoading] = useState(true);

  // State: 편집 모드
  const [isEditing, setIsEditing] = useState(false);
  const [editableText, setEditableText] = useState("");

  // State: 저장 중 상태
  const [isSaving, setIsSaving] = useState(false);

  // State: 교정 중 상태
  const [isCorrectingBasic, setIsCorrectingBasic] = useState(false);
  const [isCorrectingAI, setIsCorrectingAI] = useState(false);

  // State: 텍스트 비교 관련
  const [originalText, setOriginalText] = useState("");
  const [correctedText, setCorrectedText] = useState("");
  const [showOriginal, setShowOriginal] = useState(true);
  const [hasCorrection, setHasCorrection] = useState(false);

  // State: 스트리밍 텍스트
  const [streamingText, setStreamingText] = useState("");
  const [isStreaming, setIsStreaming] = useState(false);

  // State: 이미지 패널 표시 여부
  const [showImagePanel, setShowImagePanel] = useState(true);

  // State: 이미지 로딩 상태
  const [imageLoading, setImageLoading] = useState(true);
  const [imageError, setImageError] = useState(false);

  // State: 복습 모드
  const [reviewMode, setReviewMode] = useState(false);
  const [showForgettingCurve, setShowForgettingCurve] = useState(false);

  // Effect: 문서 상세 정보 불러오기
  useEffect(() => {
    loadDocument();
  }, [documentId]);

  // Effect: 이미지 URL 변경 감지
  useEffect(() => {
    if (document?.image_url) {
      // 이미지 URL이 변경되면 로딩 상태 초기화
      setImageLoading(true);
      setImageError(false);
    }
  }, [document?.image_url]);

  // 문서 상세 정보 불러오기
  const loadDocument = async () => {
    try {
      setIsLoading(true);
      // 이미지 상태 초기화
      setImageLoading(true);
      setImageError(false);

      const data = await getDocumentDetail(documentId);
      setDocument(data);
      setEditableText(data.extracted_text || "");
    } catch (error) {
      console.error("문서 불러오기 실패:", error);
    } finally {
      setIsLoading(false);
    }
  };

  // Handler: 편집 시작
  const handleStartEdit = () => {
    setIsEditing(true);
  };

  // Handler: 편집 취소
  const handleCancelEdit = () => {
    setEditableText(document.extracted_text || "");
    setIsEditing(false);
  };

  // Handler: 이미지 패널 토글
  const handleToggleImagePanel = () => {
    setShowImagePanel(!showImagePanel);
  };

  // Handler: 이미지 로드 완료
  const handleImageLoad = () => {
    setImageLoading(false);
    setImageError(false);
  };

  // Handler: 이미지 로드 실패
  const handleImageError = () => {
    setImageLoading(false);
    setImageError(true);
  };

  // 기본 텍스트 정리 함수 (보수적 접근)
  const correctOCRText = (text) => {
    if (!text) return text;

    // OCR에서 자주 발생하는 기본적인 오류만 수정 (띄어쓰기와 줄바꿈 최대한 보존)
    let correctedText = text
      // 연속된 공백만 하나로 (기본 띄어쓰기는 보존)
      .replace(/[ \t]{2,}/g, ' ') // 연속된 스페이스/탭만 하나로
      // 전각 숫자를 반각으로 (가장 안전한 교정)
      .replace(/０/g, '0')
      .replace(/１/g, '1')
      .replace(/２/g, '2')
      .replace(/３/g, '3')
      .replace(/４/g, '4')
      .replace(/５/g, '5')
      .replace(/６/g, '6')
      .replace(/７/g, '7')
      .replace(/８/g, '8')
      .replace(/９/g, '9')
      // 전각 문장부호를 반각으로
      .replace(/，/g, ',')
      .replace(/．/g, '.')
      .replace(/；/g, ';')
      .replace(/：/g, ':')
      // 괄호 교정
      .replace(/（/g, '(')
      .replace(/）/g, ')')
      .replace(/「/g, '"')
      .replace(/」/g, '"')
      // 문장부호 앞의 불필요한 공백만 제거 (뒤 공백은 보존)
      .replace(/\s+([,.!?])/g, '$1')
      // 줄바꿈 보존 (과도한 빈 줄만 정리)
      .replace(/\n{3,}/g, '\n\n') // 3개 이상의 줄바꿈만 2개로
      // 앞뒤 공백 제거
      .replace(/^\s+|\s+$/g, '');

    return correctedText;
  };

  // AI 고급 텍스트 교정 함수
  const aiCorrectText = (text) => {
    if (!text) return text;

    // 기본 교정부터 수행
    let correctedText = correctOCRText(text);

    // AI 스타일 고급 교정 수행
    correctedText = correctedText
      // 자주 잘못 인식되는 한글 교정
      .replace(/ㅇ([가-힣])/g, '$1') // 불필요한 'ㅇ' 제거
      .replace(/([가-힣])ㅇ/g, '$1') // 끝의 불필요한 'ㅇ' 제거
      .replace(/ㄱ([가-힣])/g, '$1') // 불필요한 'ㄱ' 제거
      .replace(/ㄴ([가-힣])/g, '$1') // 불필요한 'ㄴ' 제거
      // 자주 혼동되는 문자 교정
      .replace(/로/g, '로') // '로' → '로'
      .replace(/구/g, '구') // '구' → '구'
      // 문장 부호 정리
      .replace(/([가-힣])\s*,\s*/g, '$1, ') // 쉼표 뒤 적절한 공백
      .replace(/([가-힣])\s*\.\s*/g, '$1. ') // 마침표 뒤 적절한 공백
      .replace(/([가-힣])\s*!\s*/g, '$1! ') // 느낌표 뒤 적절한 공백
      .replace(/([가-힣])\s*\?\s*/g, '$1? ') // 물음표 뒤 적절한 공백
      // 단어 사이 적절한 띄어쓰기 (일반적인 패턴)
      .replace(/([가-힣])([0-9])/g, '$1 $2') // 한글과 숫자 사이
      .replace(/([0-9])([가-힣])/g, '$1 $2') // 숫자와 한글 사이
      .replace(/([가-힣])([A-Za-z])/g, '$1 $2') // 한글과 영어 사이
      .replace(/([A-Za-z])([가-힣])/g, '$1 $2') // 영어와 한글 사이
      // 자주 붙어서 나오는 단어들 분리
      .replace(/([가-힣])의([가-힣])/g, '$1의 $2')
      .replace(/([가-힣])과([가-힣])/g, '$1과 $2')
      .replace(/([가-힣])와([가-힣])/g, '$1와 $2')
      .replace(/([가-힣])을([가-힣])/g, '$1을 $2')
      .replace(/([가-힣])를([가-힣])/g, '$1를 $2')
      .replace(/([가-힣])에([가-힣])/g, '$1에 $2')
      .replace(/([가-힣])서([가-힣])/g, '$1서 $2')
      // 중복 교정된 공백 정리
      .replace(/\s{2,}/g, ' ')
      // 문장 끝 정리
      .replace(/([가-힣])\s*\.+/g, '$1.')
      .replace(/([가-힣])\s*!+/g, '$1!')
      .replace(/([가-힣])\s*\?+/g, '$1?')
      // 최종 정리
      .replace(/^\s+|\s+$/g, '');

    return correctedText;
  };

  // Handler: 텍스트 비교 토글
  const handleToggleTextView = () => {
    setShowOriginal(!showOriginal);
    const targetText = showOriginal ? correctedText : originalText;
    setEditableText(targetText);
  };

  // Handler: 기본 텍스트 정리
  const handleBasicCorrection = async () => {
    if (isCorrectingBasic) return;

    try {
      setIsCorrectingBasic(true);

      // 현재 텍스트 가져오기
      const textToCorrect = isEditing ? editableText : document.extracted_text;

      if (!textToCorrect) {
        alert("정리할 텍스트가 없습니다.");
        return;
      }

      // 기본 텍스트 정리
      await new Promise(resolve => setTimeout(resolve, 1000)); // 로딩 시뮬레이션

      const corrected = correctOCRText(textToCorrect);

      // 원본과 교정본 저장
      setOriginalText(textToCorrect);
      setCorrectedText(corrected);
      setHasCorrection(true);
      setShowOriginal(false); // 교정 후에는 교정된 텍스트를 먼저 보여줌

      if (isEditing) {
        setEditableText(corrected);
      } else {
        // 편집 모드가 아닌 경우 편집 모드로 전환하고 교정된 텍스트 설정
        setEditableText(corrected);
        setIsEditing(true);
      }

      console.log("기본 텍스트 정리 완료");
    } catch (error) {
      console.error("텍스트 정리 실패:", error);
      alert("텍스트 정리에 실패했습니다. 다시 시도해주세요.");
    } finally {
      setIsCorrectingBasic(false);
    }
  };

  // Handler: AI 고급 교정 (스트리밍)
  const handleAICorrection = async () => {
    if (isCorrectingAI || isStreaming) return;

    try {
      setIsCorrectingAI(true);
      setIsStreaming(true);

      // 현재 텍스트 가져오기
      const textToCorrect = isEditing ? editableText : document.extracted_text;

      if (!textToCorrect) {
        alert("교정할 텍스트가 없습니다.");
        return;
      }

      console.log("AI 스트리밍 교정 시작...");

      // 원본 텍스트를 저장 (나중에 비교용)
      setOriginalText(textToCorrect);
      setHasCorrection(true);
      setShowOriginal(false);

      // AI 교정 시작: 기존 텍스트를 지우고 AI가 교정한 텍스트로 대체
      setStreamingText("");
      setEditableText(""); // textarea를 비워서 AI 교정 결과가 처음부터 스트리밍되도록 함

      // 편집 모드로 전환 (textarea에서 스트리밍 보여주기)
      setIsEditing(true);

      // 스트리밍 API 호출
      const token = localStorage.getItem('access_token');
      const response = await fetch(
        `${import.meta.env.VITE_API_URL}/api/v1/subjects/documents/${documentId}/ai-correction-stream`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({ original_text: textToCorrect })
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      // SSE 스트림 읽기
      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = "";
      let accumulatedText = "";

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');

        // 마지막 줄은 불완전할 수 있으므로 버퍼에 유지
        buffer = lines.pop() || "";

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6);
            try {
              const parsed = JSON.parse(data);

              if (parsed.done) {
                console.log("스트리밍 완료");
                setIsStreaming(false);
                setCorrectedText(accumulatedText);
                setEditableText(accumulatedText);
                // 스트리밍 완료 후 편집 모드로 전환
                setIsEditing(true);
              } else if (parsed.text) {
                accumulatedText += parsed.text;
                setStreamingText(accumulatedText);
                // textarea에도 실시간 업데이트
                setEditableText(accumulatedText);

                // 표 구문 감지 로그
                if (parsed.text.includes('|')) {
                  console.log("표 구문 감지됨:", parsed.text);
                }
              }
            } catch (e) {
              console.error("JSON 파싱 오류:", e, "라인:", data);
            }
          }
        }
      }

      console.log("AI 스트리밍 교정 완료");
      console.log("최종 텍스트에 표 포함 여부:", accumulatedText.includes('|'));

    } catch (error) {
      console.error("AI 스트리밍 교정 실패:", error);
      alert(`AI 교정에 실패했습니다: ${error.message}`);
      setIsStreaming(false);
    } finally {
      setIsCorrectingAI(false);
    }
  };

  // Handler: 저장
  const handleSave = async () => {
    if (isSaving) return;

    try {
      setIsSaving(true);
      await updateDocument(documentId, {
        extracted_text: editableText,
      });

      // 문서 다시 불러오기
      await loadDocument();
      setIsEditing(false);
    } catch (error) {
      console.error("문서 저장 실패:", error);
      alert("문서 저장에 실패했습니다. 다시 시도해주세요.");
    } finally {
      setIsSaving(false);
    }
  };

  // 날짜 포맷팅
  const formatDate = (dateString) => {
    if (!dateString) return "";
    return new Date(dateString).toISOString().split('T')[0].replace(/-/g, '.');
  };



  if (isLoading) {
    return (
      <div className="flex-1 h-full bg-[#f1f3f5] rounded-[40px_0px_0px_40px] overflow-auto flex items-start justify-center">
        <div className="relative w-full max-w-[1178px] px-[60px] py-[60px]">
          {/* Header Skeleton */}
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-6">
              <Skeleton width="48px" height="48px" className="rounded-xl" />
              <div className="flex flex-col gap-2">
                <Skeleton width="300px" height="36px" />
                <Skeleton width="150px" height="16px" />
              </div>
            </div>
            <Skeleton width="80px" height="44px" className="rounded-2xl" />
          </div>

          {/* Content Skeleton */}
          <div className="bg-white rounded-2xl p-8 mb-6">
            <div className="space-y-3">
              {Array.from({ length: 12 }).map((_, index) => (
                <Skeleton
                  key={index}
                  width={`${Math.random() * 40 + 60}%`}
                  height="20px"
                />
              ))}
            </div>
          </div>

          {/* Metadata Skeleton */}
          <div className="bg-white rounded-2xl p-6">
            <Skeleton width="120px" height="24px" className="mb-4" />
            <div className="space-y-2">
              <Skeleton width="200px" height="16px" />
              <Skeleton width="150px" height="16px" />
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!document) {
    return (
      <div className="flex-1 h-full bg-[#f1f3f5] rounded-[40px_0px_0px_40px] overflow-auto flex items-center justify-center">
        <div className="text-[#999999] text-lg">문서를 찾을 수 없습니다</div>
      </div>
    );
  }

  return (
    <div className="flex-1 h-full bg-[#f1f3f5] rounded-[40px_0px_0px_40px] overflow-hidden flex flex-col">
      {/* Header: 상단 헤더 - 고정 */}
      <div className="bg-[#f1f3f5] px-8 pt-8 pb-6 flex-shrink-0">
        <div className="flex items-center justify-between max-w-full mx-auto">
          <div className="flex items-center gap-6">
            <button
              onClick={onBack}
              className="w-12 h-12 flex items-center justify-center rounded-xl hover:bg-white transition-colors border-0 bg-transparent cursor-pointer"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M15 18L9 12L15 6" stroke="#111111" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </button>

            <div className="flex flex-col gap-1">
              <h1 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-3xl">
                {document.title}
              </h1>
              <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm flex items-center gap-2">
                <span>{formatDate(document.created_at)}</span>
                <span>•</span>
                <span>{document.pages || 1}장</span>
              </div>
            </div>
          </div>

          {/* 편집/저장 버튼과 이미지 토글 */}
          <div className="flex items-center gap-3">
            {/* 문제풀이 모드 토글 버튼 */}
            <button
              onClick={() => setReviewMode(!reviewMode)}
              className={`px-4 py-3 rounded-2xl transition-all border-0 cursor-pointer flex items-center gap-2 ${
                reviewMode
                  ? 'bg-[#00c288] text-white'
                  : 'bg-white text-[#767676] hover:bg-[#f8f9fa]'
              }`}
              title={reviewMode ? "읽기 모드로 전환" : "문제풀이 모드로 전환"}
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <path d="M9 11L12 14L22 4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              <span className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-base">
                문제풀이
              </span>
            </button>

            {/* 기억 상태 버튼 */}
            <button
              onClick={() => setShowForgettingCurve(!showForgettingCurve)}
              className="px-4 py-3 bg-white rounded-2xl hover:bg-[#f8f9fa] transition-colors border-0 cursor-pointer flex items-center gap-2"
              title="기억 유지 상태 보기"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <path d="M3 3v18h18" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M18 9l-5 5-4-4-4 4" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              <span className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#767676] text-base">
                기억 상태
              </span>
            </button>

            {/* 원본 보기 토글 버튼 */}
            {!reviewMode && (
              <button
                onClick={handleToggleImagePanel}
                className="px-4 py-3 bg-white rounded-2xl hover:bg-[#f8f9fa] transition-colors border-0 cursor-pointer flex items-center gap-2"
                title={showImagePanel ? "원본 숨기기" : "원본 보기"}
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                  {showImagePanel ? (
                    <>
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <circle cx="12" cy="12" r="3" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <line x1="3" y1="3" x2="21" y2="21" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </>
                  ) : (
                    <>
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <circle cx="12" cy="12" r="3" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </>
                  )}
                </svg>
                <span className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#767676] text-base">
                  원본
                </span>
              </button>
            )}

            {!isEditing && !reviewMode ? (
              <button
                onClick={handleStartEdit}
                className="px-6 py-3 bg-[#00c288] rounded-2xl hover:bg-[#00a876] transition-colors border-0 cursor-pointer flex items-center gap-2"
              >
                <svg width="18" height="18" viewBox="0 0 16 16" fill="none">
                  <path d="M11.333 2A2.121 2.121 0 0 1 14 4.667L5.333 13.333 1.667 14l.667-3.667L11 2Z" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                <span className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-white text-base">
                  편집
                </span>
              </button>
            ) : (
              <>
                <button
                  onClick={handleCancelEdit}
                  className="px-6 py-3 bg-[#e0e0e0] rounded-2xl hover:bg-[#d0d0d0] transition-colors border-0 cursor-pointer"
                >
                  <span className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#505050] text-base">
                    취소
                  </span>
                </button>
                <button
                  onClick={handleSave}
                  disabled={isSaving}
                  className={`px-6 py-3 rounded-2xl transition-colors border-0 cursor-pointer flex items-center gap-2 ${
                    isSaving
                      ? 'bg-[#e0e0e0] cursor-not-allowed'
                      : 'bg-[#00c288] hover:bg-[#00a876]'
                  }`}
                >
                  {isSaving && (
                    <div className="w-4 h-4 border-2 border-[#999999] border-t-transparent rounded-full animate-spin"></div>
                  )}
                  <span className={`[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-base ${
                    isSaving ? 'text-[#999999]' : 'text-white'
                  }`}>
                    {isSaving ? '저장 중...' : '저장'}
                  </span>
                </button>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Content: 좌우 분할 영역 - 스크롤 가능 */}
      <div className="flex-1 overflow-hidden px-8 pb-8">
        {/* 망각곡선 표시 */}
        {showForgettingCurve && (
          <div className="max-w-[600px] mx-auto mb-6">
            <ForgettingCurve
              lastReviewDate={document?.last_review_date || document?.created_at}
              currentMemoryRate={28}
              nextReviewDate={new Date(Date.now() + 3 * 24 * 60 * 60 * 1000)}
            />
          </div>
        )}

        {/* 복습 모드 표시 */}
        {reviewMode ? (
          <div className="h-full max-w-[1178px] mx-auto">
            <ReviewMode
              documentContent={editableText || document?.extracted_text}
              documentTitle={document?.title}
              onComplete={(result) => {
                console.log('복습 완료:', result);
                setReviewMode(false);
                // TODO: 복습 결과 저장 API 호출
              }}
              onExit={() => setReviewMode(false)}
            />
          </div>
        ) : (
        <div className={`h-full max-w-full mx-auto flex gap-6 transition-all duration-300 ${showImagePanel ? '' : 'justify-center'}`}>
          {/* Left Panel: 원본 이미지 (고정) */}
          {showImagePanel && (
            <div className="w-1/2 flex flex-col animate-slideIn h-full">
              <h3 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-lg mb-3 flex-shrink-0">
                원본
              </h3>

              {/* 이미지 컨테이너 - 고정된 높이와 스크롤 없음 */}
              <div className="flex-1 bg-white rounded-2xl p-3 overflow-hidden mb-3">
                {document.image_url || document.original_filename ? (
                  <div className="w-full h-full flex flex-col">
                    {document.image_url ? (
                      <div className="w-full h-full flex items-start justify-center relative">
                        {imageLoading && (
                          <div className="absolute inset-0 flex items-center justify-center bg-[#f8f9fa] rounded-xl">
                            <div className="text-center">
                              <div className="w-8 h-8 border-2 border-[#00c288] border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
                              <p className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm">
                                이미지 로딩 중...
                              </p>
                            </div>
                          </div>
                        )}

                        {imageError ? (
                          <div className="w-full h-full bg-[#f8f9fa] rounded-xl flex items-center justify-center border-2 border-dashed border-[#e0e0e0]">
                            <div className="text-center">
                              <svg width="64" height="64" viewBox="0 0 24 24" fill="none" className="mx-auto mb-4">
                                <path d="M21 19V5C21 3.89543 20.1046 3 19 3H5C3.89543 3 3 3.89543 3 5V19C3 20.1046 3.89543 21 5 21H19C20.1046 21 19 20.1046 21 19Z" stroke="#ff6b6b" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                                <path d="M8.5 10C9.32843 10 10 9.32843 10 8.5C10 7.67157 9.32843 7 8.5 7C7.67157 7 7 7.67157 7 8.5C7 9.32843 7.67157 10 8.5 10Z" stroke="#ff6b6b" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                                <path d="M21 15L16 10L5 21" stroke="#ff6b6b" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                                <path d="M6 6L18 18" stroke="#ff6b6b" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                              </svg>
                              <p className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#ff6b6b] text-base mb-2">
                                이미지 로드 실패
                              </p>
                              <p className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm">
                                {document.original_filename || "이미지를 불러올 수 없습니다"}
                              </p>
                            </div>
                          </div>
                        ) : (
                          <img
                            src={document.image_url}
                            alt={document.original_filename || "업로드된 이미지"}
                            className="max-w-full max-h-full object-contain rounded-xl shadow-sm cursor-pointer hover:shadow-lg transition-shadow"
                            onLoad={handleImageLoad}
                            onError={handleImageError}
                            style={{ display: imageLoading ? 'none' : 'block' }}
                            onClick={() => window.open(document.image_url, '_blank')}
                            title="클릭하면 원본 크기로 보기"
                          />
                        )}
                      </div>
                    ) : (
                      <div className="w-full h-full bg-[#f8f9fa] rounded-xl flex items-center justify-center border-2 border-dashed border-[#e0e0e0]">
                        <div className="text-center">
                          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" className="mx-auto mb-4">
                            <path d="M21 19V5C21 3.89543 20.1046 3 19 3H5C3.89543 3 3 3.89543 3 5V19C3 20.1046 3.89543 21 5 21H19C20.1046 21 19 20.1046 21 19Z" stroke="#cccccc" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                            <path d="M8.5 10C9.32843 10 10 9.32843 10 8.5C10 7.67157 9.32843 7 8.5 7C7.67157 7 7 7.67157 7 8.5C7 9.32843 7.67157 10 8.5 10Z" stroke="#cccccc" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                            <path d="M21 15L16 10L5 21" stroke="#cccccc" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                          </svg>
                          <p className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#767676] text-base mb-2">
                            원본 이미지
                          </p>
                          <p className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm">
                            {document.original_filename}
                          </p>
                          <p className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#cccccc] text-xs mt-2">
                            이미지 URL을 사용할 수 없습니다
                          </p>
                        </div>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <div className="text-center">
                      <svg width="64" height="64" viewBox="0 0 24 24" fill="none" className="mx-auto mb-4">
                        <path d="M21 19V5C21 3.89543 20.1046 3 19 3H5C3.89543 3 3 3.89543 3 5V19C3 20.1046 3.89543 21 5 21H19C20.1046 21 19 20.1046 21 19Z" stroke="#cccccc" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M8.5 10C9.32843 10 10 9.32843 10 8.5C10 7.67157 9.32843 7 8.5 7C7.67157 7 7 7.67157 7 8.5C7 9.32843 7.67157 10 8.5 10Z" stroke="#cccccc" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M21 15L16 10L5 21" stroke="#cccccc" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                      <p className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-base">
                        원본 이미지가 없습니다
                      </p>
                    </div>
                  </div>
                )}
              </div>

              {/* Metadata: 파일명만 간단히 표시 */}
              {document.original_filename && (
                <div className="bg-[#f8f9fa] rounded-xl px-4 py-3 flex-shrink-0">
                  <div className="flex items-center gap-2">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                      <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <polyline points="13 2 13 9 20 9" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    <span className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-xs truncate">
                      {document.original_filename}
                    </span>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Right Panel: 텍스트 내용 (스크롤 가능) */}
          <div className={`flex flex-col transition-all duration-300 h-full ${showImagePanel ? 'w-1/2' : 'w-full max-w-[900px]'}`}>
            <div className="flex items-center justify-between mb-3 flex-shrink-0">
              <h3 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-lg">
                {isEditing ? '편집' : '학습 노트'}
              </h3>

              <div className="flex items-center gap-2">
                {/* AI 노트 생성 버튼만 표시 */}
                {!isEditing && (
                  <button
                    onClick={handleAICorrection}
                    disabled={isCorrectingAI}
                    className={`px-4 py-2 rounded-xl transition-colors border-0 cursor-pointer flex items-center gap-2 ${
                      isCorrectingAI
                        ? 'bg-[#f1f3f5] cursor-not-allowed'
                        : 'bg-[#00c288] hover:bg-[#00a876]'
                    }`}
                    title="AI가 학습 노트를 자동으로 생성합니다"
                  >
                    {isCorrectingAI ? (
                      <div className="w-4 h-4 border-2 border-[#999999] border-t-transparent rounded-full animate-spin"></div>
                    ) : (
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                        <path d="M12 2L13.09 8.26L20 9L13.09 9.74L12 16L10.91 9.74L4 9L10.91 8.26L12 2Z" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    )}
                    <span className={`[font-family:'Pretendard-Medium',Helvetica] font-medium text-sm ${
                      isCorrectingAI ? 'text-[#999999]' : 'text-white'
                    }`}>
                      {isCorrectingAI ? '노트 생성 중' : 'AI 노트 생성'}
                    </span>
                  </button>
                )}
              </div>
            </div>

            {/* 텍스트 컨테이너 - 스크롤 가능 */}
            <div className="flex-1 bg-white rounded-2xl overflow-hidden relative">
              {/* AI 교정 로딩 오버레이 - 스트리밍 시작 전에만 표시 */}
              {isCorrectingAI && !isStreaming && (
                <div className="absolute inset-0 bg-white bg-opacity-95 flex items-center justify-center z-10 rounded-2xl">
                  <div className="text-center">
                    <div className="w-16 h-16 border-4 border-[#667eea] border-t-transparent rounded-full animate-spin mx-auto mb-6"></div>
                    <div className="flex items-center gap-2 mb-4">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                        <path d="M12 2L13.09 8.26L20 9L13.09 9.74L12 16L10.91 9.74L4 9L10.91 8.26L12 2Z" stroke="#667eea" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                      <h3 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#667eea] text-xl">
                        AI 연결 중
                      </h3>
                    </div>
                    <p className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#666666] text-sm mb-2">
                      AWS Bedrock Claude에 연결하고 있습니다...
                    </p>
                  </div>
                </div>
              )}

              {!isEditing ? (
                <div className="h-full overflow-y-auto p-8">
                  <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#111111] text-base leading-relaxed">
                    {/* 스트리밍 중일 때는 스트리밍 텍스트 표시 */}
                    {isStreaming ? (
                      <ReactMarkdown
                        remarkPlugins={[remarkGfm]}
                        components={{
                        // 표 관련 컴포넌트 커스터마이징
                        table: ({ children }) => (
                          <div className="overflow-x-auto my-4">
                            <table className="min-w-full border-collapse border border-gray-300 rounded-lg">
                              {children}
                            </table>
                          </div>
                        ),
                        thead: ({ children }) => (
                          <thead className="bg-gray-100">{children}</thead>
                        ),
                        tbody: ({ children }) => <tbody>{children}</tbody>,
                        tr: ({ children }) => (
                          <tr className="border-b border-gray-300 hover:bg-gray-50">{children}</tr>
                        ),
                        th: ({ children }) => (
                          <th className="px-4 py-3 text-left font-semibold border border-gray-300">
                            {children}
                          </th>
                        ),
                        td: ({ children }) => (
                          <td className="px-4 py-3 border border-gray-300">
                            {children}
                          </td>
                        ),
                        // 기타 마크다운 요소 스타일링
                        h1: ({children}) => (
                          <h1 className="text-2xl font-bold text-[#111111] mt-6 mb-4 pb-2 border-b-2 border-[#00c288]">{children}</h1>
                        ),
                        h2: ({children}) => (
                          <h2 className="text-xl font-semibold text-[#111111] mt-5 mb-3">{children}</h2>
                        ),
                        h3: ({children}) => (
                          <h3 className="text-lg font-medium text-[#111111] mt-4 mb-2">{children}</h3>
                        ),
                        ul: ({children}) => (
                          <ul className="list-disc list-inside my-3 space-y-1">{children}</ul>
                        ),
                        ol: ({children}) => (
                          <ol className="list-decimal list-inside my-3 space-y-1">{children}</ol>
                        ),
                        li: ({children}) => (
                          <li className="text-[#111111] ml-2">{children}</li>
                        ),
                        p: ({children}) => (
                          <p className="my-2 leading-relaxed text-[#111111]">{children}</p>
                        ),
                        strong: ({children}) => (
                          <strong className="font-semibold text-[#111111]">{children}</strong>
                        ),
                        em: ({children}) => (
                          <em className="italic text-[#111111]">{children}</em>
                        ),
                        blockquote: ({children}) => (
                          <blockquote className="border-l-4 border-[#00c288] pl-4 my-4 italic bg-[#f8f9fa] py-2">{children}</blockquote>
                        ),
                        code: ({inline, children}) =>
                          inline ? (
                            <code className="bg-[#f1f3f5] px-2 py-1 rounded text-sm text-[#e74c3c]">{children}</code>
                          ) : (
                            <code className="block bg-[#f1f3f5] p-4 rounded-lg text-sm overflow-x-auto">{children}</code>
                          )
                      }}
                    >
                      {streamingText + (isStreaming ? "▋" : "")}
                    </ReactMarkdown>
                    ) : (
                      <ReactMarkdown
                        remarkPlugins={[remarkGfm]}
                        components={{
                          // 표 관련 컴포넌트 커스터마이징
                          table: ({ children }) => (
                            <div className="overflow-x-auto my-4">
                              <table className="min-w-full border-collapse border border-gray-300 rounded-lg">
                                {children}
                              </table>
                            </div>
                          ),
                          thead: ({ children }) => (
                            <thead className="bg-gray-100">{children}</thead>
                          ),
                          tbody: ({ children }) => <tbody>{children}</tbody>,
                          tr: ({ children }) => (
                            <tr className="border-b border-gray-300 hover:bg-gray-50">{children}</tr>
                          ),
                          th: ({ children }) => (
                            <th className="px-4 py-3 text-left font-semibold border border-gray-300">
                              {children}
                            </th>
                          ),
                          td: ({ children }) => (
                            <td className="px-4 py-3 border border-gray-300">
                              {children}
                            </td>
                          ),
                          // 기타 마크다운 요소 스타일링
                          h1: ({children}) => (
                            <h1 className="text-2xl font-bold text-[#111111] mt-6 mb-4 pb-2 border-b-2 border-[#00c288]">{children}</h1>
                          ),
                          h2: ({children}) => (
                            <h2 className="text-xl font-semibold text-[#111111] mt-5 mb-3">{children}</h2>
                          ),
                          h3: ({children}) => (
                            <h3 className="text-lg font-medium text-[#111111] mt-4 mb-2">{children}</h3>
                          ),
                          ul: ({children}) => (
                            <ul className="list-disc list-inside my-3 space-y-1">{children}</ul>
                          ),
                          ol: ({children}) => (
                            <ol className="list-decimal list-inside my-3 space-y-1">{children}</ol>
                          ),
                          li: ({children}) => (
                            <li className="text-[#111111] ml-2">{children}</li>
                          ),
                          p: ({children}) => (
                            <p className="my-2 leading-relaxed text-[#111111]">{children}</p>
                          ),
                          strong: ({children}) => (
                            <strong className="font-semibold text-[#111111]">{children}</strong>
                          ),
                          em: ({children}) => (
                            <em className="italic text-[#111111]">{children}</em>
                          ),
                          blockquote: ({children}) => (
                            <blockquote className="border-l-4 border-[#00c288] pl-4 my-4 italic bg-[#f8f9fa] py-2">{children}</blockquote>
                          ),
                          code: ({inline, children}) =>
                            inline ? (
                              <code className="bg-[#f1f3f5] px-2 py-1 rounded text-sm text-[#e74c3c]">{children}</code>
                            ) : (
                              <code className="block bg-[#f1f3f5] p-4 rounded-lg text-sm overflow-x-auto">{children}</code>
                            )
                        }}
                      >
                        {document.extracted_text || "추출된 텍스트가 없습니다."}
                      </ReactMarkdown>
                    )}
                  </div>
                </div>
              ) : (
                <div className="w-full h-full overflow-hidden rounded-2xl" data-color-mode="light">
                  <MDEditor
                    value={isStreaming ? editableText + "▋" : editableText}
                    onChange={(val) => {
                      // 스트리밍 중에는 수정 불가
                      if (!isStreaming && val !== undefined) {
                        setEditableText(val);
                      }
                    }}
                    height="100%"
                    preview="live"
                    hideToolbar={false}
                    visibleDragbar={false}
                    textareaProps={{
                      placeholder: "텍스트를 입력하세요...",
                      readOnly: isStreaming,
                      style: {
                        fontSize: '16px',
                        fontFamily: 'Pretendard-Regular, Helvetica',
                        lineHeight: '1.6'
                      }
                    }}
                    previewOptions={{
                      rehypePlugins: [],
                      remarkPlugins: [remarkGfm]
                    }}
                  />
                </div>
              )}
            </div>
          </div>
        </div>
        )}
      </div>
    </div>
  );
};
