import React, { useState, useMemo, useEffect } from "react";
import { IconCheveronLeft, IconCheveronRight } from "../../../../components/ui/icons";

export const FrameWrapper = ({ selectedDate, setSelectedDate }) => {
  // State: 사이드바 접기/펼치기 상태 관리
  const [isCollapsed, setIsCollapsed] = useState(true);

  // State: 현재 년월 관리 (Date 객체로 변경)
  const [currentMonth, setCurrentMonth] = useState(() => new Date());

  // State: 할 일 목록 관리
  const [todos, setTodos] = useState([]);

  // State: 모든 문서 데이터
  const [documents, setDocuments] = useState([]);

  // Handler: 사이드바 토글 버튼 클릭
  const handleToggleSidebar = () => {
    setIsCollapsed(!isCollapsed);
    console.log("Right sidebar toggled:", !isCollapsed);
  };

  // 캘린더 날짜 데이터 생성
  const calendarDates = useMemo(() => {
    const year = currentMonth.getFullYear();
    const month = currentMonth.getMonth();

    // 이번 달의 첫날과 마지막날
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);

    // 이번 달의 첫 주 일요일부터 시작하도록 날짜 배열 생성
    const startDayOfWeek = firstDay.getDay(); // 0(일) ~ 6(토)
    const daysInMonth = lastDay.getDate();

    const dates = [];

    // 이전 달 날짜들 (회색)
    if (startDayOfWeek > 0) {
      const prevMonth = new Date(year, month, 0);
      const prevMonthDays = prevMonth.getDate();
      for (let i = startDayOfWeek - 1; i >= 0; i--) {
        dates.push({
          date: prevMonthDays - i,
          isCurrentMonth: false,
          fullDate: new Date(year, month - 1, prevMonthDays - i)
        });
      }
    }

    // 이번 달 날짜들
    for (let i = 1; i <= daysInMonth; i++) {
      dates.push({
        date: i,
        isCurrentMonth: true,
        fullDate: new Date(year, month, i)
      });
    }

    // 다음 달 날짜들 (회색) - 35칸 채우기 (5주)
    const remainingCells = 35 - dates.length;
    for (let i = 1; i <= remainingCells; i++) {
      dates.push({
        date: i,
        isCurrentMonth: false,
        fullDate: new Date(year, month + 1, i)
      });
    }

    return dates;
  }, [currentMonth]);

  // Handler: 이전 달로 이동
  const handlePreviousMonth = () => {
    setCurrentMonth(prev => {
      const newDate = new Date(prev);
      newDate.setMonth(newDate.getMonth() - 1);
      return newDate;
    });
  };

  // Handler: 다음 달로 이동
  const handleNextMonth = () => {
    setCurrentMonth(prev => {
      const newDate = new Date(prev);
      newDate.setMonth(newDate.getMonth() + 1);
      return newDate;
    });
  };

  // Handler: 날짜 클릭
  const handleDateClick = (dateObj) => {
    // 같은 날짜를 다시 클릭하면 선택 해제
    if (selectedDate && selectedDate.toDateString() === dateObj.fullDate.toDateString()) {
      setSelectedDate(null);
    } else {
      setSelectedDate(dateObj.fullDate);
    }
  };

  // Handler: 알림 아이콘 클릭
  const handleNotificationClick = () => {
    console.log("Notification clicked");
    alert("알림이 없습니다.");
  };

  // Effect: 모든 과목과 문서 데이터 가져오기
  useEffect(() => {
    const fetchDocuments = async () => {
      try {
        // 1. 먼저 모든 과목 가져오기
        const subjectsResponse = await fetch('https://y1ec4xig1c.execute-api.us-east-1.amazonaws.com/dev/api/v1/subjects');
        const subjects = await subjectsResponse.json();

        // 2. 각 과목의 문서들 가져오기
        const allDocuments = [];
        for (const subject of subjects) {
          const docsResponse = await fetch(`https://y1ec4xig1c.execute-api.us-east-1.amazonaws.com/dev/api/v1/subjects/${subject.subject_id}/documents`);
          const docs = await docsResponse.json();
          // 각 문서에 과목 이름 추가
          docs.forEach(doc => {
            doc.subject_name = subject.name;
            doc.document_name = doc.title;
          });
          allDocuments.push(...docs);
        }

        setDocuments(allDocuments);
      } catch (error) {
        console.error('Error fetching documents:', error);
      }
    };

    fetchDocuments();
  }, []);

  // Effect: 선택된 날짜의 문서로 할 일 목록 필터링
  useEffect(() => {
    if (!selectedDate || documents.length === 0) {
      setTodos([]);
      return;
    }

    // 선택된 날짜의 문서만 필터링
    const filtered = documents.filter(doc => {
      if (!doc.created_at) return false;

      // UTC 시간을 한국 시간(KST, UTC+9)으로 변환
      const docDate = new Date(doc.created_at);
      const kstOffset = 9 * 60; // 9시간을 분으로 환산
      const localOffset = docDate.getTimezoneOffset();
      const kstTime = new Date(docDate.getTime() + (kstOffset + localOffset) * 60 * 1000);

      // 날짜만 비교 (년-월-일)
      const selectedYear = selectedDate.getFullYear();
      const selectedMonth = selectedDate.getMonth();
      const selectedDay = selectedDate.getDate();

      const docYear = kstTime.getFullYear();
      const docMonth = kstTime.getMonth();
      const docDay = kstTime.getDate();

      return selectedYear === docYear && selectedMonth === docMonth && selectedDay === docDay;
    });

    // 문서를 할 일 형식으로 변환
    const todoItems = filtered.map(doc => ({
      id: doc.document_id,
      subject: doc.subject_name,
      title: doc.document_name,
      completed: doc.review_completed || false
    }));

    setTodos(todoItems);
  }, [selectedDate, documents]);

  // Handler: 체크박스 토글
  const handleTodoToggle = async (todoId) => {
    try {
      // 백엔드 API 호출
      const response = await fetch(`https://y1ec4xig1c.execute-api.us-east-1.amazonaws.com/dev/api/v1/subjects/documents/${todoId}/review`, {
        method: 'PATCH'
      });

      if (response.ok) {
        const updatedDocument = await response.json();

        // UI 업데이트
        setTodos(prevTodos =>
          prevTodos.map(todo =>
            todo.id === todoId ? { ...todo, completed: updatedDocument.review_completed } : todo
          )
        );
      } else {
        console.error('Failed to toggle review status');
      }
    } catch (error) {
      console.error('Error toggling review status:', error);
    }
  };

  return (
    <div className={`flex-shrink-0 h-full flex bg-white rounded-[40px_0px_0px_40px] overflow-hidden transition-all duration-300 ${isCollapsed ? 'w-[80px]' : 'w-[480px]'}`}>
      {/* Toggle button: 사이드바 접기/펼치기 버튼 */}
      <button
        onClick={handleToggleSidebar}
        className="mt-8 w-10 h-10 ml-8 flex rounded-lg hover:bg-gray-100 cursor-pointer transition-colors border-0 bg-transparent"
      >
        {isCollapsed ? (
          <IconCheveronLeft className="w-8 h-8 m-1" />
        ) : (
          <IconCheveronRight className="w-8 h-8 m-1" />
        )}
      </button>

      {/* Content: 사이드바 컨텐츠 (접혔을 때 숨김) */}
      <div className={`flex mt-[72px] w-[310px] h-[696px] relative ml-[13px] flex-col items-center transition-opacity duration-300 ${isCollapsed ? 'opacity-0 pointer-events-none' : 'opacity-100'}`}>
        <div className="flex flex-col w-[177px] items-center gap-[70px] relative flex-[0_0_auto]">
          <div className="flex flex-col w-[152px] items-center gap-4 relative flex-[0_0_auto]">
            <img
              className="relative w-[120px] h-[120px] aspect-[1] object-cover"
              alt="Ellipse"
              src="https://c.animaapp.com/acBhPnRI/img/ellipse-3.svg"
            />

            <div className="flex flex-col items-center gap-8 relative self-stretch w-full flex-[0_0_auto]">
              <div className="flex flex-col w-[97px] items-center relative flex-[0_0_auto]">
                <div className="relative self-stretch mt-[-1.00px] [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-black text-xl tracking-[-0.50px] leading-[28.0px]">
                  User Name
                </div>

                <div className="relative self-stretch [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-neutraln-100 text-sm text-center tracking-[-0.35px] leading-[19.6px]">
                  Pro 이용중
                </div>
              </div>

              <div className="flex flex-col items-start gap-3 relative self-stretch w-full flex-[0_0_auto]">
                <div className="relative self-stretch mt-[-1.00px] [font-family:'Pretendard_Variable-Medium',Helvetica] font-medium text-black text-base tracking-[-0.40px] leading-[22.4px]">
                  인하대학교 컴퓨터공학과
                </div>

                <div className="relative self-stretch [font-family:'Pretendard_Variable-SemiBold',Helvetica] font-semibold text-black text-xl text-center tracking-[-0.50px] leading-[28.0px]">
                  25-2학기
                </div>
              </div>
            </div>
          </div>

          {/* Calendar navigation: 달력 월 이동 */}
          <div className="flex items-center gap-5 relative self-stretch w-full flex-[0_0_auto]">
            <button
              onClick={handlePreviousMonth}
              className="relative w-7 h-7 rounded-lg overflow-hidden hover:bg-gray-100 active:scale-90 cursor-pointer transition-all duration-200 border-0 bg-transparent flex items-center justify-center"
            >
              <IconCheveronLeft className="w-5 h-5" />
            </button>

            <div className="relative w-fit [font-family:'Pretendard-Regular',Helvetica] font-normal text-black text-base text-center tracking-[-0.40px] leading-[22.4px] whitespace-nowrap">
              {currentMonth.getFullYear()}년 {currentMonth.getMonth() + 1}월
            </div>

            <button
              onClick={handleNextMonth}
              className="relative w-7 h-7 rounded-lg overflow-hidden hover:bg-gray-100 active:scale-90 cursor-pointer transition-all duration-200 border-0 bg-transparent flex items-center justify-center"
            >
              <IconCheveronRight className="w-5 h-5" />
            </button>
          </div>
        </div>

        <div className="flex flex-col items-start relative self-stretch w-full flex-[0_0_auto]">
          <div className="flex h-11 items-center relative self-stretch w-full">
            <div className="relative w-[46px] h-11">
              <div className="bg-white absolute top-0 left-0 w-11 h-11" />

              <div className="absolute top-3.5 left-4 [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm text-center tracking-[-0.35px] leading-[19.6px] whitespace-nowrap">
                일
              </div>
            </div>

            <div className="relative w-[46px] h-11">
              <div className="bg-white absolute top-0 left-0 w-11 h-11" />

              <div className="absolute top-3.5 left-4 [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm text-center tracking-[-0.35px] leading-[19.6px] whitespace-nowrap">
                월
              </div>
            </div>

            <div className="relative w-[46px] h-11">
              <div className="bg-white absolute top-0 left-0 w-11 h-11" />

              <div className="absolute top-3.5 left-4 [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm text-center tracking-[-0.35px] leading-[19.6px] whitespace-nowrap">
                화
              </div>
            </div>

            <div className="relative w-[46px] h-11">
              <div className="bg-white absolute top-0 left-0 w-11 h-11" />

              <div className="absolute top-3.5 left-4 [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm text-center tracking-[-0.35px] leading-[19.6px] whitespace-nowrap">
                수
              </div>
            </div>

            <div className="relative w-[46px] h-11">
              <div className="bg-white absolute top-0 left-0 w-11 h-11" />

              <div className="absolute top-3.5 left-4 [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm text-center tracking-[-0.35px] leading-[19.6px] whitespace-nowrap">
                목
              </div>
            </div>

            <div className="relative w-[46px] h-11">
              <div className="bg-white absolute top-0 left-0 w-11 h-11" />

              <div className="absolute top-3.5 left-4 [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm text-center tracking-[-0.35px] leading-[19.6px] whitespace-nowrap">
                금
              </div>
            </div>

            <div className="relative w-[46px] h-11">
              <div className="bg-white absolute top-0 left-0 w-11 h-11" />

              <div className="absolute top-3.5 left-4 [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm text-center tracking-[-0.35px] leading-[19.6px] whitespace-nowrap">
                토
              </div>
            </div>
          </div>

          <div className="flex flex-col items-center relative self-stretch w-full flex-[0_0_auto]">
            {/* Calendar dates dynamically generated */}
            {Array.from({ length: 5 }).map((_, weekIndex) => {
              const today = new Date();
              return (
                <div key={weekIndex} className="flex h-[50px] items-center pt-0 pb-1.5 px-0 relative self-stretch w-full">
                  {calendarDates.slice(weekIndex * 7, (weekIndex + 1) * 7).map((dateObj, dayIndex) => {
                    const globalIndex = weekIndex * 7 + dayIndex;
                    const isToday = dateObj.fullDate.toDateString() === today.toDateString();
                    const isSelected = selectedDate && dateObj.fullDate.toDateString() === selectedDate.toDateString();
                    const isSunday = dayIndex === 0;

                    return (
                      <button
                        key={globalIndex}
                        onClick={() => handleDateClick(dateObj)}
                        className="relative w-[46px] h-11 border-0 bg-transparent cursor-pointer hover:opacity-70 active:scale-90 transition-all duration-200"
                      >
                        <div className={`absolute top-0 left-0 w-11 h-11 ${
                          isSelected ? 'bg-[#00c288] rounded-xl' : isToday ? 'bg-[#f1f3f5] rounded-xl' : 'bg-white'
                        }`} />

                        <div className={`absolute top-3.5 ${dateObj.date >= 10 ? 'left-3.5' : 'left-[17px]'} [font-family:'${
                          isSelected ? 'Pretendard-Medium' : 'Pretendard-Regular'
                        }',Helvetica] ${isSelected ? 'font-medium' : 'font-normal'} text-base text-center tracking-[-0.40px] leading-[22.4px] whitespace-nowrap ${
                          isSelected
                            ? 'text-white'
                            : dateObj.isCurrentMonth
                            ? isSunday
                              ? 'text-[#f1706d]'
                              : 'text-[#111111]'
                            : 'text-[#999999]'
                        }`}>
                          {dateObj.date}
                        </div>
                      </button>
                    );
                  })}
                </div>
              );
            })}

            <div className="inline-flex items-center gap-[3px] absolute top-[97px] left-[100px]">
              <div className="relative w-[5px] h-[5px] bg-sub-1 rounded-[2.5px]" />

              <div className="relative w-[5px] h-[5px] bg-main rounded-[2.5px]" />

              <div className="relative w-[5px] h-[5px] bg-main rounded-[2.5px]" />
            </div>
          </div>
        </div>

        {/* Todo List Section: 할 일 목록 */}
        {selectedDate && (
          <div className="flex flex-col items-start gap-4 relative self-stretch w-full flex-[0_0_auto] mt-6">
            {/* 선택된 날짜 표시 */}
            <div className="relative self-stretch [font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-black text-base tracking-[-0.40px] leading-[22.4px]">
              {selectedDate.getMonth() + 1}월 {selectedDate.getDate()}일 할 일
            </div>

            {/* 할 일 목록 */}
            <div className="flex flex-col items-start gap-3 relative self-stretch w-full max-h-[200px] overflow-y-auto">
              {todos.length === 0 ? (
                <div className="relative self-stretch [font-family:'Pretendard-Regular',Helvetica] font-normal text-[#999999] text-sm tracking-[-0.35px] leading-[19.6px]">
                  이 날짜에 업로드된 문서가 없습니다.
                </div>
              ) : (
                todos.map(todo => (
                  <div
                    key={todo.id}
                    className="flex items-center gap-3 relative self-stretch w-full p-3 bg-[#f8f8f8] rounded-lg hover:bg-[#eeeeee] transition-colors"
                  >
                    <button
                      onClick={() => handleTodoToggle(todo.id)}
                      className="flex-shrink-0 w-5 h-5 rounded border-2 border-[#999999] hover:border-[#00c288] hover:scale-110 active:scale-95 transition-all duration-200 cursor-pointer bg-transparent flex items-center justify-center"
                      style={{
                        backgroundColor: todo.completed ? '#00c288' : 'transparent',
                        borderColor: todo.completed ? '#00c288' : '#999999'
                      }}
                    >
                      {todo.completed && (
                        <svg width="12" height="9" viewBox="0 0 12 9" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M1 4.5L4.5 8L11 1" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        </svg>
                      )}
                    </button>
                    <div className="flex flex-col gap-1 flex-1">
                      <div
                        className={`[font-family:'Pretendard-Medium',Helvetica] font-medium text-sm tracking-[-0.35px] leading-[19.6px] ${
                          todo.completed ? 'text-[#999999] line-through' : 'text-black'
                        }`}
                      >
                        {todo.subject}
                      </div>
                      <div
                        className={`[font-family:'Pretendard-Regular',Helvetica] font-normal text-xs tracking-[-0.30px] leading-[16.8px] ${
                          todo.completed ? 'text-[#cccccc]' : 'text-[#666666]'
                        }`}
                      >
                        {todo.title}
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}
      </div>

      {/* Notification button: 알림 버튼 */}
      <button
        onClick={handleNotificationClick}
        className="mt-[42px] w-8 h-8 ml-[21px] flex aspect-[1] bg-[url(https://c.animaapp.com/acBhPnRI/img/icon-bell-1.svg)] bg-[100%_100%] hover:opacity-70 hover:scale-110 active:scale-95 cursor-pointer transition-all duration-200 border-0"
      >
        <div className="mt-[5px] w-2 h-2 ml-5 bg-second rounded" />
      </button>
    </div>
  );
};
