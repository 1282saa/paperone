/**
 * useOCR Hook
 * OCR 처리 관련 상태와 로직을 관리하는 커스텀 훅
 */

import { useState, useCallback } from 'react';
import { extractTextFromImage, validateImageFile } from '../utils/ocrService';
import { uploadImageToS3 } from '../services/subjectsApi';
import { compressImage } from '../lib/utils';
import { IMAGE_COMPRESSION } from '../constants';

/**
 * OCR 처리 훅
 * @returns {Object} OCR 상태 및 액션
 */
export const useOCR = () => {
  const [isProcessing, setIsProcessing] = useState(false);
  const [ocrResult, setOcrResult] = useState(null);
  const [uploadedImageFile, setUploadedImageFile] = useState(null);
  const [editableText, setEditableText] = useState('');

  /**
   * 이미지 파일 처리 및 OCR 실행
   * @param {File} file - 이미지 파일
   * @returns {Promise<boolean>} 성공 여부
   */
  const processImage = useCallback(async (file) => {
    // 파일 유효성 검사
    const validation = validateImageFile(file);
    if (!validation.valid) {
      console.error('파일 유효성 검사 실패:', validation.error);
      return false;
    }

    setIsProcessing(true);
    setOcrResult(null);
    setUploadedImageFile(file);

    try {
      // AWS Textract를 사용하여 텍스트 추출
      const result = await extractTextFromImage(file);

      if (result.success) {
        setOcrResult(result);
        setEditableText(result.text);
        return true;
      } else {
        console.error('텍스트 추출 실패:', result.error);
        setUploadedImageFile(null);
        return false;
      }
    } catch (error) {
      console.error('이미지 처리 중 오류:', error);
      setUploadedImageFile(null);
      return false;
    } finally {
      setIsProcessing(false);
    }
  }, []);

  /**
   * 이미지 업로드 (압축 후 S3 업로드)
   * @param {File} file - 원본 이미지 파일
   * @returns {Promise<string|null>} 업로드된 이미지 URL 또는 null
   */
  const uploadImage = useCallback(async (file) => {
    if (!file) return null;

    try {
      // 이미지 압축
      const compressedFile = await compressImage(file, {
        quality: IMAGE_COMPRESSION.QUALITY,
        maxWidth: IMAGE_COMPRESSION.MAX_WIDTH,
        maxHeight: IMAGE_COMPRESSION.MAX_HEIGHT,
      });

      if (!compressedFile) {
        throw new Error("이미지 압축 실패");
      }

      // S3 업로드 시도
      try {
        const uploadResult = await uploadImageToS3(compressedFile);
        return uploadResult.image_url;
      } catch (s3Error) {
        // S3 실패 시 base64 폴백
        console.warn('S3 업로드 실패, base64로 폴백:', s3Error);
        const reader = new FileReader();
        return new Promise((resolve, reject) => {
          reader.onload = () => resolve(reader.result);
          reader.onerror = reject;
          reader.readAsDataURL(compressedFile);
        });
      }
    } catch (error) {
      console.error("이미지 처리 실패:", error);

      // 원본 파일로 재시도
      try {
        const reader = new FileReader();
        return new Promise((resolve, reject) => {
          reader.onload = () => resolve(reader.result);
          reader.onerror = reject;
          reader.readAsDataURL(file);
        });
      } catch (finalError) {
        console.error("원본 파일 변환 실패:", finalError);
        return null;
      }
    }
  }, []);

  /**
   * OCR 상태 초기화
   */
  const reset = useCallback(() => {
    setOcrResult(null);
    setEditableText('');
    setUploadedImageFile(null);
    setIsProcessing(false);
  }, []);

  return {
    // 상태
    isProcessing,
    ocrResult,
    uploadedImageFile,
    editableText,

    // 액션
    processImage,
    uploadImage,
    setEditableText,
    reset,
  };
};
