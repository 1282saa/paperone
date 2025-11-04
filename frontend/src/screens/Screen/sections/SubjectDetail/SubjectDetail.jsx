/**
 * SubjectDetail Component (Refactored)
 * 과목 상세 화면 - 단일 책임 원칙 적용, 커스텀 훅 및 컴포넌트 분리
 */

import React, { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useDocuments } from "../../../../hooks/useDocuments";
import { useOCR } from "../../../../hooks/useOCR";
import { DocumentListItem } from "../../../../components/domain/documents/DocumentListItem";
import { BottomSheet, BottomSheetOption } from "../../../../components/common/BottomSheet";
import { OCRResultModal } from "../../../../components/domain/ocr/OCRResultModal";
import { ListItemSkeleton } from "../../../../components/ui/Skeleton";

export const SubjectDetail = ({ subjectName, subjectId, selectedDate, onBack }) => {
  const navigate = useNavigate();

  // 커스텀 훅 사용
  const {
    filteredDocuments,
    isLoading,
    deletingId,
    loadDocuments,
    createDocument,
    updateDocument: updateDocumentApi,
    deleteDocument: deleteDocumentApi,
  } = useDocuments(subjectId, selectedDate);

  const {
    isProcessing,
    ocrResult,
    uploadedImageFile,
    editableText,
    processImage,
    uploadImage,
    setEditableText,
    reset: resetOCR,
  } = useOCR();

  // 로컬 상태
  const [showBottomSheet, setShowBottomSheet] = useState(false);
  const [showOcrResultModal, setShowOcrResultModal] = useState(false);
  const [editingDocument, setEditingDocument] = useState(null);
  const [editDocumentTitle, setEditDocumentTitle] = useState("");
  const [isUpdatingDocument, setIsUpdatingDocument] = useState(false);

  // Refs
  const fileInputRef = useRef(null);
  const cameraInputRef = useRef(null);

  // 과목 ID가 변경되면 문서 목록 로드
  useEffect(() => {
    if (subjectId) {
      loadDocuments();
    }
  }, [subjectId, loadDocuments]);

  // Handler: 문서 클릭
  const handleDocumentClick = (documentId) => {
    navigate(`/review/subject/${subjectId}/document/${documentId}`);
  };

  // Handler: 이미지 파일 처리
  const handleFileSelect = async (file) => {
    if (!file) return;

    const success = await processImage(file);
    if (success) {
      setShowOcrResultModal(true);
    }
  };

  // Handler: 카메라 파일 선택
  const handleCameraFileChange = (event) => {
    const file = event.target.files?.[0];
    if (file) {
      handleFileSelect(file);
    }
    event.target.value = "";
  };

  // Handler: 파일 업로드 선택
  const handleFileChange = (event) => {
    const file = event.target.files?.[0];
    if (file) {
      handleFileSelect(file);
    }
    event.target.value = "";
  };

  // Handler: 텍스트 저장
  const handleSaveText = async () => {
    if (!editableText.trim() || !subjectId) {
      return;
    }

    try {
      // 문서 제목 생성 (첫 줄 또는 기본값)
      const titleFromText = editableText.split('\n')[0].substring(0, 50) || "새 문서";

      // 이미지 업로드
      let imageUrl = null;
      if (uploadedImageFile) {
        imageUrl = await uploadImage(uploadedImageFile);
        if (!imageUrl) {
          alert('이미지 처리에 실패했습니다.\n이미지 없이 텍스트만 저장됩니다.');
        }
      }

      // 문서 데이터 생성
      const documentData = {
        subject_id: subjectId,
        title: titleFromText,
        extracted_text: editableText,
        original_filename: uploadedImageFile?.name || ocrResult?.fileName || "uploaded_image.jpg",
        file_size: uploadedImageFile?.size || 0,
        pages: 1,
      };

      if (imageUrl) {
        documentData.image_url = imageUrl;
      }

      // 문서 저장
      const success = await createDocument(documentData);
      if (success) {
        handleCloseOcrResultModal();
      } else {
        alert("문서 저장에 실패했습니다. 다시 시도해주세요.");
      }
    } catch (error) {
      console.error("문서 저장 실패:", error);
      alert("문서 저장에 실패했습니다. 다시 시도해주세요.");
    }
  };

  // Handler: OCR 결과 모달 닫기
  const handleCloseOcrResultModal = () => {
    setShowOcrResultModal(false);
    resetOCR();
  };

  // Handler: 문서 제목 수정
  const handleEditDocument = (e, doc) => {
    e.stopPropagation();
    setEditingDocument(doc);
    setEditDocumentTitle(doc.title);
  };

  // Handler: 문서 제목 수정 제출
  const handleSubmitEditDocument = async (e) => {
    e.preventDefault();
    if (!editDocumentTitle.trim() || editDocumentTitle.trim() === editingDocument.title) {
      return;
    }

    setIsUpdatingDocument(true);
    const success = await updateDocumentApi(editingDocument.document_id, {
      title: editDocumentTitle.trim(),
    });

    if (success) {
      setEditingDocument(null);
      setEditDocumentTitle("");
    } else {
      alert('문서 제목 수정에 실패했습니다. 다시 시도해주세요.');
    }
    setIsUpdatingDocument(false);
  };

  // Handler: 문서 삭제
  const handleDeleteDocument = async (e, doc) => {
    e.stopPropagation();

    const success = await deleteDocumentApi(doc.document_id);
    if (!success) {
      alert('문서 삭제에 실패했습니다. 다시 시도해주세요.');
    }
  };

  return (
    <div className="flex-1 h-full bg-[#f1f3f5] rounded-[40px_0px_0px_40px] overflow-auto flex items-start justify-center">
      <div className="relative w-full max-w-[1178px] px-[60px] py-[60px]">

        {/* Header */}
        <div className="flex items-center gap-6 mb-8">
          <button
            onClick={onBack}
            className="w-12 h-12 flex items-center justify-center rounded-xl hover:bg-white transition-colors border-0 bg-transparent cursor-pointer"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
              <path d="M15 18L9 12L15 6" stroke="#111111" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>

          <h1 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-3xl">
            {subjectName}
          </h1>

          {selectedDate && (
            <div className="ml-4 px-4 py-2 bg-[#00c288] text-white rounded-full [font-family:'Pretendard-Medium',Helvetica] font-medium text-sm">
              {selectedDate.toLocaleDateString('ko-KR', { month: 'long', day: 'numeric' })} 문서만 표시 중
            </div>
          )}
        </div>

        {/* Documents List */}
        <div className="flex flex-col gap-4">
          {isLoading ? (
            <div className="flex flex-col gap-4">
              {Array.from({ length: 3 }).map((_, index) => (
                <ListItemSkeleton key={index} />
              ))}
            </div>
          ) : filteredDocuments.length === 0 ? (
            <div className="bg-white rounded-2xl p-12 flex flex-col items-center justify-center gap-4">
              <svg width="64" height="64" viewBox="0 0 24 24" fill="none">
                <path d="M14 2H6C5.46957 2 4.96086 2.21071 4.58579 2.58579C4.21071 2.96086 4 3.46957 4 4V20C4 20.5304 4.21071 21.0391 4.58579 21.4142C4.96086 21.7893 5.46957 22 6 22H18C18.5304 22 19.0391 21.7893 19.4142 21.4142C19.7893 21.0391 20 20.5304 20 20V8L14 2Z" stroke="#d0d0d0" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M14 2V8H20" stroke="#d0d0d0" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              <div className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#999999] text-lg">
                {selectedDate ? '선택한 날짜에 저장된 문서가 없습니다' : '아직 저장된 문서가 없습니다'}
              </div>
              <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#cccccc] text-sm">
                {selectedDate ? '다른 날짜를 선택하거나 문서를 추가해보세요' : '오늘한장 작성하기로 문서를 추가해보세요'}
              </div>
            </div>
          ) : (
            filteredDocuments.map((doc) => (
              <DocumentListItem
                key={doc.document_id}
                document={doc}
                onClick={() => handleDocumentClick(doc.document_id)}
                onEdit={(e) => handleEditDocument(e, doc)}
                onDelete={(e) => handleDeleteDocument(e, doc)}
                isDeleting={deletingId === doc.document_id}
              />
            ))
          )}
        </div>

        {/* Floating Action Button */}
        <button
          onClick={() => setShowBottomSheet(true)}
          className="fixed bottom-[60px] right-[60px] flex items-center gap-2 px-8 py-4 bg-[#00c288] rounded-full shadow-lg hover:bg-[#00a876] hover:shadow-2xl hover:scale-110 active:scale-95 transition-all duration-300 border-0 cursor-pointer"
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d="M12 5V19M5 12H19" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <span className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-white text-base">
            오늘한장 작성하기
          </span>
        </button>

        {/* Hidden File Inputs */}
        <input
          ref={cameraInputRef}
          type="file"
          accept="image/*"
          capture="environment"
          onChange={handleCameraFileChange}
          className="hidden"
        />
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          onChange={handleFileChange}
          className="hidden"
        />

        {/* Processing Indicator */}
        {isProcessing && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 animate-fade-in">
            <div className="bg-white rounded-3xl p-10 flex flex-col items-center gap-6 max-w-[400px] animate-scale-in">
              <div className="relative">
                <div className="w-16 h-16 border-4 border-[#e0e0e0] border-t-[#00c288] rounded-full animate-spin"></div>
                <div className="absolute inset-0 w-16 h-16 border-4 border-transparent border-b-[#00c288] rounded-full animate-spin animate-reverse" style={{animationDelay: '0.5s'}}></div>
              </div>
              <div className="text-center">
                <div className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-xl mb-2">
                  AI가 텍스트를 추출하고 있어요
                </div>
                <div className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-base">
                  잠시만 기다려주세요...
                </div>
              </div>
              <div className="flex items-center gap-3 w-full">
                <div className="flex-1 h-2 bg-[#e0e0e0] rounded-full overflow-hidden">
                  <div className="h-full bg-gradient-to-r from-[#00c288] to-[#00a876] rounded-full animate-pulse w-3/4 transition-all duration-1000"></div>
                </div>
                <span className="[font-family:'Pretendard-Medium',Helvetica] font-medium text-[#00c288] text-sm">75%</span>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* OCR Result Modal */}
      <OCRResultModal
        isOpen={showOcrResultModal}
        onClose={handleCloseOcrResultModal}
        onSave={handleSaveText}
        ocrResult={ocrResult}
        imageFile={uploadedImageFile}
        editableText={editableText}
        onTextChange={setEditableText}
        isSaving={isProcessing}
      />

      {/* Bottom Sheet Modal */}
      <BottomSheet
        isOpen={showBottomSheet}
        onClose={() => setShowBottomSheet(false)}
        title="오늘한장 작성하기"
      >
        <div className="flex flex-col gap-4">
          <BottomSheetOption
            onClick={() => {
              setShowBottomSheet(false);
              cameraInputRef.current?.click();
            }}
            icon={
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M23 19C23 19.5304 22.7893 20.0391 22.4142 20.4142C22.0391 20.7893 21.5304 21 21 21H3C2.46957 21 1.96086 20.7893 1.58579 20.4142C1.21071 20.0391 1 19.5304 1 19V8C1 7.46957 1.21071 6.96086 1.58579 6.58579C1.96086 6.21071 2.46957 6 3 6H7L9 3H15L17 6H21C21.5304 6 22.0391 6.21071 22.4142 6.58579C22.7893 6.96086 23 7.46957 23 8V19Z" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M12 17C14.2091 17 16 15.2091 16 13C16 10.7909 14.2091 9 12 9C9.79086 9 8 10.7909 8 13C8 15.2091 9.79086 17 12 17Z" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            }
            title="사진 찍기"
            description="카메라로 직접 촬영하기"
          />
          <BottomSheetOption
            onClick={() => {
              setShowBottomSheet(false);
              fileInputRef.current?.click();
            }}
            icon={
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M21 15V19C21 19.5304 20.7893 20.0391 20.4142 20.4142C20.0391 20.7893 19.5304 21 19 21H5C4.46957 21 3.96086 20.7893 3.58579 20.4142C3.21071 20.0391 3 19.5304 3 19V15" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M17 8L12 3L7 8" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M12 3V15" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            }
            title="파일 업로드"
            description="갤러리에서 선택하기"
          />
        </div>
      </BottomSheet>

      {/* Edit Document Modal */}
      {editingDocument && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 animate-fade-in"
          onClick={() => setEditingDocument(null)}
        >
          <div
            className="bg-white rounded-[32px] w-full max-w-[500px] p-8 animate-scale-in"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-2xl mb-6">
              문서 제목 수정
            </h2>
            <form onSubmit={handleSubmitEditDocument}>
              <input
                type="text"
                value={editDocumentTitle}
                onChange={(e) => setEditDocumentTitle(e.target.value)}
                placeholder="문서 제목을 입력하세요"
                className="w-full px-6 py-4 bg-[#f1f3f5] rounded-2xl [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#111111] text-base focus:outline-none focus:ring-2 focus:ring-[#00c288] border-0 mb-6"
                autoFocus
              />
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setEditingDocument(null)}
                  className="flex-1 h-14 flex items-center justify-center bg-[#e0e0e0] rounded-2xl hover:bg-[#d0d0d0] active:scale-95 transition-all duration-200 border-0 cursor-pointer"
                >
                  <span className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#505050] text-base">
                    취소
                  </span>
                </button>
                <button
                  type="submit"
                  disabled={isUpdatingDocument}
                  className={`flex-1 h-14 flex items-center justify-center rounded-2xl transition-all duration-200 border-0 cursor-pointer ${
                    isUpdatingDocument
                      ? 'bg-[#e0e0e0] cursor-not-allowed'
                      : 'bg-[#00c288] hover:bg-[#00a876] active:scale-95'
                  }`}
                >
                  {isUpdatingDocument ? (
                    <div className="flex items-center gap-2">
                      <div className="w-4 h-4 border-2 border-[#999999] border-t-transparent rounded-full animate-spin"></div>
                      <span className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#999999] text-base">
                        저장 중...
                      </span>
                    </div>
                  ) : (
                    <span className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-white text-base">
                      저장
                    </span>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
