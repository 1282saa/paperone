import React, { useState, useEffect } from 'react';

export const ReviewMode = ({
  documentContent,
  documentTitle,
  onComplete,
  onExit
}) => {
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [questions, setQuestions] = useState([]);
  const [answers, setAnswers] = useState([]);
  const [currentAnswer, setCurrentAnswer] = useState('');
  const [showFeedback, setShowFeedback] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);
  const [score, setScore] = useState(0);
  const [startTime, setStartTime] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [showResults, setShowResults] = useState(false);

  useEffect(() => {
    generateQuestions();
    setStartTime(new Date());
  }, [documentContent]);

  const generateQuestions = async () => {
    setIsLoading(true);

    // TODO: 실제 AI API 호출
    const mockQuestions = [
      {
        type: 'fill-blank',
        question: '에빙하우스의 ___에 따르면 학습 후 24시간이 지나면 ___% 정도를 잊어버린다.',
        blanks: ['망각곡선', '70'],
        hint: '기억과 관련된 이론'
      },
      {
        type: 'multiple-choice',
        question: '다음 중 효과적인 복습 주기로 가장 적절한 것은?',
        options: [
          '매일 복습',
          '1일, 3일, 7일, 30일 간격',
          '일주일에 한 번',
          '시험 전날 몰아서'
        ],
        correctAnswer: 1,
        explanation: '망각곡선을 고려한 간격 반복 학습이 효과적입니다.'
      },
      {
        type: 'short-answer',
        question: '장기기억으로 전환하기 위한 가장 중요한 방법은 무엇인가요?',
        keywords: ['반복', '복습', '간격'],
        explanation: '일정한 간격을 두고 반복 학습하는 것이 중요합니다.'
      }
    ];

    setQuestions(mockQuestions);
    setIsLoading(false);
  };

  const checkAnswer = () => {
    const question = questions[currentQuestionIndex];
    let correct = false;

    switch (question.type) {
      case 'fill-blank':
        const userAnswers = currentAnswer.split(',').map(a => a.trim().toLowerCase());
        const correctAnswers = question.blanks.map(a => a.toLowerCase());
        correct = JSON.stringify(userAnswers) === JSON.stringify(correctAnswers);
        break;

      case 'multiple-choice':
        correct = parseInt(currentAnswer) === question.correctAnswer;
        break;

      case 'short-answer':
        const lowerAnswer = currentAnswer.toLowerCase();
        correct = question.keywords.some(keyword =>
          lowerAnswer.includes(keyword.toLowerCase())
        );
        break;
    }

    setIsCorrect(correct);
    setShowFeedback(true);

    if (correct) {
      setScore(score + 1);
    }

    setAnswers([...answers, {
      questionIndex: currentQuestionIndex,
      userAnswer: currentAnswer,
      isCorrect: correct
    }]);
  };

  const nextQuestion = () => {
    if (currentQuestionIndex < questions.length - 1) {
      setCurrentQuestionIndex(currentQuestionIndex + 1);
      setCurrentAnswer('');
      setShowFeedback(false);
      setIsCorrect(false);
    } else {
      finishReview();
    }
  };

  const finishReview = () => {
    const endTime = new Date();
    const duration = Math.round((endTime - startTime) / 1000);
    const scorePercent = Math.round((score / questions.length) * 100);

    setShowResults(true);

    if (onComplete) {
      onComplete({
        score: scorePercent,
        duration: duration,
        totalQuestions: questions.length,
        correctAnswers: score,
        answers: answers
      });
    }
  };

  // 로딩 화면
  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-96">
        <div className="w-12 h-12 border-3 border-[#00c288] border-t-transparent rounded-full animate-spin mb-4"></div>
        <p className="text-base font-medium text-[#767676]">문제 준비 중</p>
      </div>
    );
  }

  // 결과 화면
  if (showResults) {
    const scorePercent = Math.round((score / questions.length) * 100);
    const duration = Math.round((new Date() - startTime) / 1000);
    const nextReviewDays = scorePercent >= 80 ? 7 : 3;

    return (
      <div className="bg-white rounded-2xl p-12 text-center max-w-2xl mx-auto">
        {/* 결과 표시 */}
        <div className="mb-8">
          <div className="w-20 h-20 mx-auto mb-4 rounded-full bg-[#f1f3f5] flex items-center justify-center">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none">
              <path d="M9 11L12 14L22 4" stroke="#00c288" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" stroke="#00c288" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-[#111111] mb-2">복습 완료</h2>
          <p className="text-[#767676]">
            {scorePercent >= 80 ? '우수' : scorePercent >= 60 ? '양호' : '보통'}
          </p>
        </div>

        {/* 통계 */}
        <div className="grid grid-cols-3 gap-4 mb-8">
          <div className="bg-[#f8f9fa] rounded-xl p-6">
            <div className="text-3xl font-bold text-[#111111] mb-1">
              {scorePercent}%
            </div>
            <div className="text-sm text-[#767676]">정답률</div>
          </div>
          <div className="bg-[#f8f9fa] rounded-xl p-6">
            <div className="text-3xl font-bold text-[#111111] mb-1">
              {score}/{questions.length}
            </div>
            <div className="text-sm text-[#767676]">정답 수</div>
          </div>
          <div className="bg-[#f8f9fa] rounded-xl p-6">
            <div className="text-3xl font-bold text-[#111111] mb-1">
              {Math.floor(duration / 60)}분
            </div>
            <div className="text-sm text-[#767676]">소요 시간</div>
          </div>
        </div>

        {/* 다음 복습 일정 */}
        <div className="bg-[#f1f3f5] rounded-xl p-6 mb-6">
          <p className="text-sm text-[#767676] mb-2">다음 복습 예정</p>
          <p className="text-xl font-bold text-[#111111] mb-2">
            {new Date(Date.now() + nextReviewDays * 24 * 60 * 60 * 1000).toLocaleDateString('ko-KR', {
              year: 'numeric',
              month: 'long',
              day: 'numeric'
            })}
          </p>
          <p className="text-sm text-[#767676]">
            {nextReviewDays}일 후
          </p>
        </div>

        {/* 액션 버튼 */}
        <div className="flex gap-3">
          <button
            onClick={onExit}
            className="flex-1 py-3 bg-[#f1f3f5] rounded-xl font-medium text-[#767676] hover:bg-[#e8eaed] transition-colors"
          >
            완료
          </button>
          {score < questions.length && (
            <button
              onClick={() => {
                setCurrentQuestionIndex(0);
                setScore(0);
                setAnswers([]);
                setShowResults(false);
                setCurrentAnswer('');
                setShowFeedback(false);
              }}
              className="flex-1 py-3 bg-[#00c288] text-white rounded-xl font-medium hover:bg-[#00a876] transition-colors"
            >
              다시 풀기
            </button>
          )}
        </div>
      </div>
    );
  }

  const currentQuestion = questions[currentQuestionIndex];
  const progress = ((currentQuestionIndex + 1) / questions.length) * 100;

  return (
    <div className="max-w-3xl mx-auto">
      {/* 진행 상태 */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm font-medium text-[#767676]">
            {currentQuestionIndex + 1} / {questions.length}
          </span>
          <span className="text-sm font-medium text-[#00c288]">
            {score}점
          </span>
        </div>
        <div className="w-full h-2 bg-[#f0f0f0] rounded-full overflow-hidden">
          <div
            className="h-full bg-[#00c288] transition-all duration-300"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      {/* 문제 */}
      <div className="bg-white rounded-2xl p-8 shadow-sm border border-[#f0f0f0] mb-6">
        <div className="mb-6">
          <p className="text-lg leading-relaxed text-[#111111]">
            {currentQuestion.question}
          </p>
        </div>

        {/* 답변 입력 */}
        <div className="mb-6">
          {currentQuestion.type === 'fill-blank' && (
            <div>
              <input
                type="text"
                value={currentAnswer}
                onChange={(e) => setCurrentAnswer(e.target.value)}
                placeholder="답을 쉼표로 구분하여 입력"
                className="w-full px-4 py-3 border border-[#e0e0e0] rounded-xl focus:border-[#00c288] focus:outline-none"
                disabled={showFeedback}
              />
              {currentQuestion.hint && !showFeedback && (
                <p className="text-sm text-[#999999] mt-2">{currentQuestion.hint}</p>
              )}
            </div>
          )}

          {currentQuestion.type === 'multiple-choice' && (
            <div className="space-y-3">
              {currentQuestion.options.map((option, idx) => (
                <button
                  key={idx}
                  onClick={() => !showFeedback && setCurrentAnswer(idx.toString())}
                  className={`w-full p-4 rounded-xl text-left border transition-all ${
                    currentAnswer === idx.toString()
                      ? 'border-[#00c288] bg-[#f8f9fa]'
                      : 'border-[#e0e0e0] hover:border-[#d0d0d0]'
                  } ${showFeedback && idx === currentQuestion.correctAnswer ? 'border-[#00c288] bg-[#e8f5e9]' : ''}
                  ${showFeedback && currentAnswer === idx.toString() && idx !== currentQuestion.correctAnswer ? 'border-[#ff6b6b] bg-[#fff5f5]' : ''}`}
                  disabled={showFeedback}
                >
                  <span className="font-medium text-[#767676] mr-2">{String.fromCharCode(65 + idx)}.</span>
                  <span className="text-[#111111]">{option}</span>
                </button>
              ))}
            </div>
          )}

          {currentQuestion.type === 'short-answer' && (
            <textarea
              value={currentAnswer}
              onChange={(e) => setCurrentAnswer(e.target.value)}
              placeholder="답변 입력"
              className="w-full h-32 px-4 py-3 border border-[#e0e0e0] rounded-xl focus:border-[#00c288] focus:outline-none resize-none"
              disabled={showFeedback}
            />
          )}
        </div>

        {/* 피드백 */}
        {showFeedback && (
          <div className={`p-4 rounded-xl mb-6 border ${
            isCorrect
              ? 'bg-[#e8f5e9] border-[#c8e6c9]'
              : 'bg-[#fff5f5] border-[#ffcdd2]'
          }`}>
            <div className="flex items-start gap-3">
              <div className={`w-6 h-6 rounded-full flex items-center justify-center ${
                isCorrect ? 'bg-[#00c288]' : 'bg-[#ff6b6b]'
              }`}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  {isCorrect ? (
                    <path d="M5 13l4 4L19 7" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  ) : (
                    <path d="M18 6L6 18M6 6l12 12" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  )}
                </svg>
              </div>
              <div>
                <p className="font-medium text-[#111111] mb-1">
                  {isCorrect ? '정답' : '오답'}
                </p>
                {currentQuestion.explanation && (
                  <p className="text-sm text-[#767676]">{currentQuestion.explanation}</p>
                )}
                {!isCorrect && currentQuestion.type === 'fill-blank' && (
                  <p className="text-sm text-[#767676] mt-2">
                    정답: {currentQuestion.blanks.join(', ')}
                  </p>
                )}
              </div>
            </div>
          </div>
        )}

        {/* 액션 버튼 */}
        <div className="flex gap-3">
          {!showFeedback ? (
            <>
              <button
                onClick={() => {
                  setCurrentAnswer('');
                  nextQuestion();
                }}
                className="flex-1 py-3 bg-[#f1f3f5] rounded-xl font-medium text-[#767676] hover:bg-[#e8eaed] transition-colors"
              >
                건너뛰기
              </button>
              <button
                onClick={checkAnswer}
                disabled={!currentAnswer}
                className={`flex-1 py-3 rounded-xl font-medium transition-all ${
                  currentAnswer
                    ? 'bg-[#00c288] text-white hover:bg-[#00a876]'
                    : 'bg-[#e0e0e0] text-[#999999] cursor-not-allowed'
                }`}
              >
                확인
              </button>
            </>
          ) : (
            <button
              onClick={nextQuestion}
              className="w-full py-3 bg-[#00c288] text-white rounded-xl font-medium hover:bg-[#00a876] transition-all"
            >
              {currentQuestionIndex < questions.length - 1 ? '다음' : '결과 보기'}
            </button>
          )}
        </div>
      </div>

      {/* 나가기 */}
      <button
        onClick={onExit}
        className="text-[#767676] hover:text-[#111111] transition-colors text-sm"
      >
        ← 나가기
      </button>
    </div>
  );
};
