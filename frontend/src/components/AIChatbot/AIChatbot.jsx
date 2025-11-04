import React, { useState, useRef, useEffect } from 'react';
import { chatWithAI } from '../../services/aiApi';

export const AIChatbot = ({ onClose }) => {
  const [messages, setMessages] = useState([
    {
      role: 'assistant',
      content: '안녕하세요! AI 학습 도우미입니다.\n무엇을 도와드릴까요?'
    }
  ]);
  const [inputMessage, setInputMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [conversationId, setConversationId] = useState(null);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = async () => {
    if (!inputMessage.trim() || isLoading) return;

    const userMessage = inputMessage.trim();
    setInputMessage('');

    // 사용자 메시지 추가
    setMessages(prev => [...prev, { role: 'user', content: userMessage }]);
    setIsLoading(true);

    try {
      // OpenAI API 호출
      const response = await chatWithAI(userMessage, conversationId);

      // conversation_id 저장 (첫 메시지일 경우)
      if (!conversationId && response.conversation_id) {
        setConversationId(response.conversation_id);
      }

      // AI 응답 추가
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: response.message
      }]);
    } catch (error) {
      console.error('AI 응답 실패:', error);
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: '죄송합니다. 응답을 생성하는데 실패했습니다. 다시 시도해주세요.\n\n오류: ' + error.message
      }]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 animate-fadeIn">
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-2xl h-[600px] flex flex-col animate-slideUp">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-[#00c288] to-[#00a876] rounded-full flex items-center justify-center">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                <path d="M12 2L13.09 8.26L20 9L13.09 9.74L12 16L10.91 9.74L4 9L10.91 8.26L12 2Z" fill="white"/>
              </svg>
            </div>
            <div>
              <h2 className="[font-family:'Pretendard-SemiBold',Helvetica] font-semibold text-[#111111] text-lg">
                AI 학습 도우미
              </h2>
              <p className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-[#767676] text-xs">
                궁금한 내용을 물어보세요
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 transition-colors border-0 bg-transparent cursor-pointer"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <path d="M18 6L6 18M6 6L18 18" stroke="#767676" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto px-6 py-4 space-y-4">
          {messages.map((message, index) => (
            <div
              key={index}
              className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-[80%] rounded-2xl px-4 py-3 ${
                  message.role === 'user'
                    ? 'bg-[#00c288] text-white'
                    : 'bg-[#f8f9fa] text-[#111111]'
                }`}
              >
                <p className="[font-family:'Pretendard-Regular',Helvetica] font-normal text-sm leading-relaxed whitespace-pre-wrap">
                  {message.content}
                </p>
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-[#f8f9fa] rounded-2xl px-4 py-3">
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 bg-[#767676] rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
                  <div className="w-2 h-2 bg-[#767676] rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
                  <div className="w-2 h-2 bg-[#767676] rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input */}
        <div className="px-6 py-4 border-t border-gray-200">
          <div className="flex items-center gap-3">
            <input
              type="text"
              value={inputMessage}
              onChange={(e) => setInputMessage(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="궁금한 내용을 입력하세요..."
              className="flex-1 px-4 py-3 rounded-xl border border-gray-300 focus:outline-none focus:ring-2 focus:ring-[#00c288] focus:border-transparent [font-family:'Pretendard-Regular',Helvetica] font-normal text-sm"
              disabled={isLoading}
            />
            <button
              onClick={handleSendMessage}
              disabled={!inputMessage.trim() || isLoading}
              className={`w-12 h-12 flex items-center justify-center rounded-xl transition-colors border-0 cursor-pointer ${
                !inputMessage.trim() || isLoading
                  ? 'bg-gray-200 cursor-not-allowed'
                  : 'bg-[#00c288] hover:bg-[#00a876]'
              }`}
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                <path d="M22 2L11 13M22 2L15 22L11 13M22 2L2 9L11 13" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
