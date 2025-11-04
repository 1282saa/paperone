import React, { useState } from "react";
import {
  AcademicCapIcon,
  IconCalendar,
  IconChartBar,
  IconChat,
  IconClipboardCheck,
  IconClipboardList,
  IconCog,
  IconEmojiHappy,
  IconLogout,
  IconSparkles
} from "../../../../components/ui/icons";
import { logout } from "../../../../services/authApi";
import { AIChatbot } from "../../../../components/AIChatbot/AIChatbot";

export const Frame = ({ activeMenu, setActiveMenu, onLogout }) => {
  const [showChatbot, setShowChatbot] = useState(false);

  // Handler: 메뉴 클릭
  const handleMenuClick = (menuName) => {
    // 부드러운 전환을 위한 애니메이션 클래스 추가
    const content = document.querySelector('.main-content');
    if (content) {
      content.classList.add('animate-fadeIn');
    }

    setActiveMenu(menuName);
    console.log("Menu clicked:", menuName);
  };

  // Handler: 로그아웃
  const handleLogout = () => {
    console.log("Logout clicked");
    logout(); // 토큰 삭제
    if (onLogout) {
      onLogout(); // 로그인 화면으로 이동
    }
  };

  // Handler: AI 문제 생성 클릭
  const handleAiProblemGeneration = () => {
    console.log("AI 문제 생성 clicked");
    setShowChatbot(true);
  };

  // Handler: AI 튜터 복습이 클릭
  const handleAiTutor = () => {
    console.log("AI 튜터 복습이 clicked");
    alert("AI 튜터 복습이 페이지로 이동합니다.");
  };

  // Handler: 계정 설정 클릭
  const handleAccountSettings = () => {
    console.log("계정 설정 clicked");
    alert("계정 설정 페이지로 이동합니다.");
  };

  // Handler: FAQ 클릭
  const handleFaq = () => {
    console.log("FAQ clicked");
    alert("FAQ 페이지로 이동합니다.");
  };

  // Handler: 요금제 비교 클릭
  const handlePricingComparison = () => {
    console.log("요금제 비교 clicked");
    alert("요금제 비교 페이지로 이동합니다.");
  };

  return (
    <div className="flex-shrink-0 w-[309px] h-full flex flex-col bg-white">
      <img
        className="ml-10 w-[182px] h-[79px] mt-[50px] mb-8"
        alt="Frame"
        src="https://c.animaapp.com/acBhPnRI/img/frame-1707481723.png"
      />

      <div className="flex w-[260px] flex-1 relative flex-col items-center justify-between pb-8">
        <div className="flex flex-col items-start gap-[52px] relative self-stretch w-full flex-[0_0_auto]">
          <div className="relative self-stretch w-full h-[264px]">
            {/* Main navigation menu: 메인 네비게이션 메뉴 */}
            <div className="flex flex-col w-[260px] items-start absolute top-10 left-0">
              <button
                onClick={() => handleMenuClick('home')}
                className="flex h-14 items-center gap-2 pl-8 pr-0 py-0 relative self-stretch w-full cursor-pointer hover:bg-[#f8f9fa] active:scale-[0.98] transition-all duration-200 border-0 bg-transparent"
              >
                {activeMenu === 'home' && <div className="absolute top-0 left-5 w-[220px] h-14 bg-[#00c288] rounded-xl" />}
                <AcademicCapIcon className={`w-6 h-6 ${activeMenu === 'home' ? 'text-white z-10 relative' : 'text-[#505050]'}`} />
                <div className={`relative w-fit [font-family:'Pretendard_Variable-${activeMenu === 'home' ? 'SemiBold' : 'Medium'}',Helvetica] ${activeMenu === 'home' ? 'font-semibold text-white z-10' : 'font-medium text-[#505050]'} text-base tracking-[-0.40px] leading-[22.4px] whitespace-nowrap`}>
                  홈
                </div>
              </button>

              <button
                onClick={() => handleMenuClick('review')}
                className="flex h-14 items-center gap-2 pl-8 pr-0 py-0 relative self-stretch w-full cursor-pointer hover:bg-[#f8f9fa] active:scale-[0.98] transition-all duration-200 border-0 bg-transparent"
              >
                {activeMenu === 'review' && <div className="absolute top-0 left-5 w-[220px] h-14 bg-[#00c288] rounded-xl" />}
                <IconClipboardCheck className={`w-6 h-6 ${activeMenu === 'review' ? 'text-white z-10 relative' : 'text-[#505050]'}`} />
                <div className={`relative w-fit [font-family:'Pretendard_Variable-${activeMenu === 'review' ? 'SemiBold' : 'Medium'}',Helvetica] ${activeMenu === 'review' ? 'font-semibold text-white z-10' : 'font-medium text-[#505050]'} text-base tracking-[-0.40px] leading-[22.4px] whitespace-nowrap`}>
                  백지복습
                </div>
              </button>

              <button
                onClick={() => handleMenuClick('stats')}
                className="flex h-14 items-center gap-2 pl-8 pr-0 py-0 relative self-stretch w-full cursor-pointer hover:bg-[#f8f9fa] active:scale-[0.98] transition-all duration-200 border-0 bg-transparent"
              >
                {activeMenu === 'stats' && <div className="absolute top-0 left-5 w-[220px] h-14 bg-[#00c288] rounded-xl" />}
                <IconChartBar className={`w-6 h-6 ${activeMenu === 'stats' ? 'text-white z-10 relative' : 'text-[#505050]'}`} />
                <div className={`relative w-fit [font-family:'Pretendard_Variable-${activeMenu === 'stats' ? 'SemiBold' : 'Medium'}',Helvetica] ${activeMenu === 'stats' ? 'font-semibold text-white z-10' : 'font-medium text-[#505050]'} text-base tracking-[-0.40px] leading-[22.4px] whitespace-nowrap`}>
                  학습 통계
                </div>
              </button>
            </div>

            <div className="absolute top-0 left-8 [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-black text-sm tracking-[-0.35px] leading-[19.6px] whitespace-nowrap">
              학습 관리
            </div>
          </div>

          <div className="relative self-stretch w-full h-[264px]">
            {/* Quick Actions: 빠른 실행 메뉴 */}
            <div className="flex flex-col w-[260px] items-start absolute top-10 left-0">
              <button
                onClick={handleAiProblemGeneration}
                className="flex h-14 items-center gap-2 pl-8 pr-0 py-0 relative self-stretch w-full cursor-pointer hover:bg-[#f8f9fa] active:scale-[0.98] transition-all duration-200 border-0 bg-transparent"
              >
                <IconClipboardList className="w-6 h-6" />
                <div className="relative w-fit [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-[#505050] text-base tracking-[-0.40px] leading-[22.4px] whitespace-nowrap">
                  AI 문제 생성
                </div>
              </button>

              <button
                onClick={handleAiTutor}
                className="flex h-14 items-center gap-2 pl-8 pr-0 py-0 relative self-stretch w-full cursor-pointer hover:bg-[#f8f9fa] active:scale-[0.98] transition-all duration-200 border-0 bg-transparent"
              >
                <IconSparkles className="w-6 h-6" />
                <div className="relative w-fit [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-[#505050] text-base tracking-[-0.40px] leading-[22.4px] whitespace-nowrap">
                  AI 튜터 복습이
                </div>
              </button>
            </div>

            <div className="absolute top-0 left-8 [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-black text-sm tracking-[-0.35px] leading-[19.6px] whitespace-nowrap">
              빠른 실행
            </div>
          </div>
        </div>

        {/* Footer Links: 하단 링크 섹션 */}
        <div className="inline-flex items-end gap-8 relative flex-[0_0_auto]">
          <div className="flex flex-col w-[86px] items-start gap-4 relative">
            <button
              onClick={handleAccountSettings}
              className="inline-flex items-start gap-2 relative flex-[0_0_auto] cursor-pointer hover:opacity-70 hover:translate-x-1 active:scale-95 transition-all duration-200 border-0 bg-transparent"
            >
              <IconCog className="w-5 h-5" />
              <div className="relative w-fit mt-[-1.00px] [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-[#505050] text-[13px] tracking-[-0.33px] leading-[18.2px] whitespace-nowrap">
                계정 설정
              </div>
            </button>

            <button
              onClick={handleFaq}
              className="inline-flex items-center gap-2 relative flex-[0_0_auto] cursor-pointer hover:opacity-70 hover:translate-x-1 active:scale-95 transition-all duration-200 border-0 bg-transparent"
            >
              <IconChat className="w-5 h-5" />
              <div className="relative w-fit [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-[#505050] text-[13px] tracking-[-0.33px] leading-[18.2px] whitespace-nowrap">
                FAQ
              </div>
            </button>

            <button
              onClick={handlePricingComparison}
              className="flex items-start gap-2 relative self-stretch w-full flex-[0_0_auto] cursor-pointer hover:opacity-70 hover:translate-x-1 active:scale-95 transition-all duration-200 border-0 bg-transparent"
            >
              <IconEmojiHappy className="w-5 h-5" />
              <div className="relative w-fit mt-[-1.00px] [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-[#505050] text-[13px] tracking-[-0.33px] leading-[18.2px] whitespace-nowrap">
                요금제 비교
              </div>
            </button>
          </div>

          <button
            onClick={handleLogout}
            className="inline-flex items-start gap-2 relative flex-[0_0_auto] cursor-pointer hover:opacity-70 hover:translate-x-1 active:scale-95 transition-all duration-200 border-0 bg-transparent"
          >
            <IconLogout className="w-5 h-5" />
            <div className="relative w-fit mt-[-1.00px] [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-[#505050] text-[13px] tracking-[-0.33px] leading-[18.2px] whitespace-nowrap">
              로그아웃
            </div>
          </button>
        </div>
      </div>

      {/* AI 챗봇 모달 */}
      {showChatbot && (
        <AIChatbot onClose={() => setShowChatbot(false)} />
      )}
    </div>
  );
};
