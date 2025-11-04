import React, { useState, useEffect } from "react";
import { Routes, Route, useNavigate, useLocation } from "react-router-dom";
import { DivWrapper } from "./sections/DivWrapper";
import { Frame } from "./sections/Frame";
import { FrameWrapper } from "./sections/FrameWrapper";
import { ReviewPage } from "../../pages/ReviewPage";

export const Screen = ({ onLogout }) => {
  const navigate = useNavigate();
  const location = useLocation();

  // State: 현재 활성화된 메뉴 (Frame과 공유)
  const [activeMenu, setActiveMenu] = useState('home');
  // State: 전역 선택 날짜 (ReviewContent, FrameWrapper와 공유)
  const [selectedDate, setSelectedDate] = useState(null);

  // URL 경로에 따라 activeMenu 설정
  useEffect(() => {
    const path = location.pathname;
    if (path === '/' || path === '/home') {
      setActiveMenu('home');
    } else if (path.startsWith('/review')) {
      // /review, /review/subject/*, /review/subject/*/document/* 모두 review로 처리
      setActiveMenu('review');
    } else if (path === '/stats') {
      setActiveMenu('stats');
    }
  }, [location]);

  // activeMenu 변경 시 URL도 함께 변경
  const handleMenuChange = (menu) => {
    setActiveMenu(menu);
    if (menu === 'home') {
      navigate('/');
    } else {
      navigate(`/${menu}`);
    }
  };

  return (
    <div
      className="bg-[#f8f8f8] w-screen h-screen flex overflow-hidden"
      data-model-id="9:59"
    >
      <Frame activeMenu={activeMenu} setActiveMenu={handleMenuChange} onLogout={onLogout} />
      <Routes>
        <Route path="/" element={<DivWrapper />} />
        <Route path="/home" element={<DivWrapper />} />
        <Route path="/review" element={<ReviewPage selectedDate={selectedDate} setSelectedDate={setSelectedDate} />} />
        <Route path="/review/subject/:subjectId" element={<ReviewPage selectedDate={selectedDate} setSelectedDate={setSelectedDate} />} />
        <Route path="/review/subject/:subjectId/document/:documentId" element={<ReviewPage selectedDate={selectedDate} setSelectedDate={setSelectedDate} />} />
        <Route path="/stats" element={<DivWrapper />} />
        <Route path="/*" element={<DivWrapper />} />
      </Routes>
      <FrameWrapper selectedDate={selectedDate} setSelectedDate={setSelectedDate} />
    </div>
  );
};
