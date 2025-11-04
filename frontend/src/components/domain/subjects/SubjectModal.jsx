/**
 * SubjectModal Component
 * 과목 추가/수정 모달 컴포넌트
 */

import React, { useState } from 'react';
import { Modal } from '../../common/Modal';
import { Button } from '../../common/Button';

export const SubjectModal = ({
  isOpen,
  onClose,
  onSubmit,
  mode = "create", // create, edit
  initialValue = ""
}) => {
  const [subjectName, setSubjectName] = useState(initialValue);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!subjectName.trim()) return;

    const success = await onSubmit({ name: subjectName.trim() });
    if (success) {
      setSubjectName("");
      onClose();
    }
  };

  const handleClose = () => {
    setSubjectName("");
    onClose();
  };

  const title = mode === "create" ? "과목 추가하기" : "과목 이름 수정";

  return (
    <Modal isOpen={isOpen} onClose={handleClose} title={title}>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={subjectName}
          onChange={(e) => setSubjectName(e.target.value)}
          placeholder="과목 이름을 입력하세요"
          className="w-full px-4 py-3 bg-[#f1f3f5] rounded-2xl [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#111111] text-base focus:outline-none focus:ring-2 focus:ring-[#00c288] border-0 mb-6"
          autoFocus
        />
        <div className="flex gap-3">
          <Button
            variant="secondary"
            onClick={handleClose}
            className="flex-1"
          >
            취소
          </Button>
          <Button
            type="submit"
            variant="primary"
            className="flex-1"
          >
            {mode === "create" ? "추가" : "수정"}
          </Button>
        </div>
      </form>
    </Modal>
  );
};