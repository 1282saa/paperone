import Tesseract from 'tesseract.js';

/**
 * 이미지 파일에서 텍스트를 추출하는 함수 (Tesseract.js 사용 - 한글 지원)
 * @param {File} file - 분석할 이미지 파일 (jpg, png 등)
 * @param {Function} onProgress - 진행률 콜백 함수 (선택사항)
 * @returns {Promise<Object>} - 추출된 텍스트와 신뢰도 정보
 */
export const extractTextFromImage = async (file, onProgress = null) => {
  try {
    // Tesseract.js를 사용하여 OCR 수행
    // 'kor+eng' - 한글과 영어를 모두 인식
    const result = await Tesseract.recognize(
      file,
      'kor+eng',
      {
        logger: (info) => {
          // 진행률 정보 로깅
          if (info.status === 'recognizing text' && onProgress) {
            onProgress(Math.round(info.progress * 100));
          }
          console.log('OCR 진행:', info.status, info.progress);
        },
      }
    );

    // 추출된 텍스트
    const fullText = result.data.text || "";

    // 라인별로 분리 (빈 줄 제거)
    const lines = (result.data.lines || [])
      .filter(line => line && line.text && line.text.trim() !== '')
      .map(line => ({
        text: line.text,
        confidence: line.confidence || 0,
      }));

    // 평균 신뢰도 계산
    const avgConfidence =
      lines.length > 0
        ? lines.reduce((sum, line) => sum + line.confidence, 0) / lines.length
        : result.data.confidence || 0;

    return {
      success: true,
      text: fullText,
      lines: lines,
      confidence: avgConfidence.toFixed(2),
      blockCount: (result.data.blocks || []).length,
    };
  } catch (error) {
    console.error("OCR 처리 중 오류 발생:", error);

    // 에러 타입별 메시지 처리
    let errorMessage = "텍스트 추출 중 오류가 발생했습니다.";

    if (error.message) {
      errorMessage = error.message;
    }

    return {
      success: false,
      error: errorMessage,
      text: "",
      lines: [],
      confidence: 0,
    };
  }
};

/**
 * 이미지 파일 유효성 검사 함수
 * @param {File} file - 검사할 파일
 * @returns {Object} - 유효성 검사 결과
 */
export const validateImageFile = (file) => {
  // 파일 존재 여부 확인
  if (!file) {
    return { valid: false, error: "파일이 선택되지 않았습니다." };
  }

  // 파일 크기 확인 (최대 5MB)
  const maxSize = 5 * 1024 * 1024; // 5MB
  if (file.size > maxSize) {
    return { valid: false, error: "파일 크기는 5MB 이하여야 합니다." };
  }

  // 파일 타입 확인 (이미지만 허용)
  const allowedTypes = ["image/jpeg", "image/jpg", "image/png", "image/bmp", "image/tiff"];
  if (!allowedTypes.includes(file.type)) {
    return {
      valid: false,
      error: "지원하지 않는 파일 형식입니다. JPG, PNG, BMP, TIFF 파일만 업로드 가능합니다."
    };
  }

  return { valid: true };
};
