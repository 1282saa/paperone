import React, { useState } from 'react';
import { login, register, confirmEmail, resendCode } from '../services/authApi';

export const LoginScreen = ({ onLoginSuccess }) => {
  const [isLogin, setIsLogin] = useState(true);
  const [needsConfirmation, setNeedsConfirmation] = useState(false);
  const [confirmationCode, setConfirmationCode] = useState('');
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    name: ''
  });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);

    try {
      let response;
      if (isLogin) {
        response = await login(formData.email, formData.password);

        // 토큰 저장
        localStorage.setItem('access_token', response.access_token);
        if (response.id_token) {
          localStorage.setItem('id_token', response.id_token);
        }
        if (response.refresh_token) {
          localStorage.setItem('refresh_token', response.refresh_token);
        }

        // 로그인 성공 콜백
        onLoginSuccess();
      } else {
        // 회원가입 - 이메일 인증 필요
        response = await register(formData.email, formData.password, formData.name);
        setNeedsConfirmation(true);
        setSuccess('회원가입이 완료되었습니다! 이메일로 전송된 인증 코드를 입력해주세요.');
      }
    } catch (err) {
      setError(err.message || (isLogin ? '로그인에 실패했습니다.' : '회원가입에 실패했습니다.'));
    } finally {
      setLoading(false);
    }
  };

  const handleConfirmEmail = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);

    try {
      await confirmEmail(formData.email, confirmationCode);
      setSuccess('이메일 인증이 완료되었습니다! 로그인해주세요.');

      // 3초 후 로그인 화면으로 전환
      setTimeout(() => {
        setNeedsConfirmation(false);
        setIsLogin(true);
        setConfirmationCode('');
        setSuccess('');
      }, 3000);
    } catch (err) {
      setError(err.message || '인증 코드가 올바르지 않습니다.');
    } finally {
      setLoading(false);
    }
  };

  const handleResendCode = async () => {
    setError('');
    setSuccess('');
    setLoading(true);

    try {
      await resendCode(formData.email);
      setSuccess('인증 코드가 재전송되었습니다. 이메일을 확인해주세요.');
    } catch (err) {
      setError(err.message || '인증 코드 재전송에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#f8fafc] via-[#f1f5f9] to-[#e2e8f0] flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        {/* 로고 및 타이틀 */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-[#111111] mb-2">
            {needsConfirmation ? '이메일 인증' : isLogin ? '로그인' : '회원가입'}
          </h1>
          <p className="text-[#767676]">
            {needsConfirmation
              ? '이메일로 전송된 인증 코드를 입력해주세요'
              : isLogin ? '백지 복습 서비스에 오신 것을 환영합니다' : '새 계정을 만들어보세요'}
          </p>
        </div>

        {/* 이메일 인증 폼 */}
        {needsConfirmation ? (
          <div className="bg-white/95 backdrop-blur-sm rounded-3xl shadow-[0px_20px_60px_rgba(0,0,0,0.08)] border-0 p-10">
            <form onSubmit={handleConfirmEmail} className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-[#111111] mb-2">
                  인증 코드
                </label>
                <input
                  type="text"
                  value={confirmationCode}
                  onChange={(e) => setConfirmationCode(e.target.value)}
                  required
                  className="w-full px-4 py-4 rounded-xl border-0 bg-blue-50 focus:outline-none focus:ring-2 focus:ring-[#00c288]/20 transition-all duration-200 text-[#111111] placeholder-[#9ca3af] shadow-sm"
                  placeholder="123456"
                  maxLength={6}
                />
                <p className="text-xs text-[#767676] mt-1">
                  {formData.email}로 전송된 6자리 코드를 입력해주세요.
                </p>
              </div>

              {success && (
                <div className="bg-green-50/80 border-0 text-green-700 px-4 py-3 rounded-xl text-sm shadow-sm">
                  {success}
                </div>
              )}

              {error && (
                <div className="bg-red-50/80 border-0 text-red-700 px-4 py-3 rounded-xl text-sm shadow-sm">
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-[#00c288] text-white py-4 rounded-xl font-semibold hover:bg-[#00a876] hover:shadow-lg active:scale-[0.98] transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed relative z-10 border-0 outline-none"
                style={{
                  background: loading ? '#9ca3af' : 'linear-gradient(90deg, #00c288 0%, #00a876 100%)',
                  color: '#ffffff',
                  fontWeight: '600',
                  border: 'none',
                  outline: 'none'
                }}
              >
                <span className="relative z-10 text-white font-semibold">
                  {loading ? '확인 중...' : '인증하기'}
                </span>
              </button>

              <button
                type="button"
                onClick={handleResendCode}
                disabled={loading}
                className="w-full text-[#00c288] hover:underline text-sm"
              >
                인증 코드 재전송
              </button>
            </form>

            <div className="mt-6 text-center">
              <button
                onClick={() => {
                  setNeedsConfirmation(false);
                  setConfirmationCode('');
                  setError('');
                  setSuccess('');
                }}
                className="text-[#767676] hover:underline text-sm"
              >
                뒤로 가기
              </button>
            </div>
          </div>
        ) : (
          /* 로그인/회원가입 폼 */
          <div className="bg-white/95 backdrop-blur-sm rounded-3xl shadow-[0px_20px_60px_rgba(0,0,0,0.08)] border-0 p-10">
            <form onSubmit={handleSubmit} className="space-y-6">
            {!isLogin && (
              <div>
                <label className="block text-sm font-medium text-[#111111] mb-2">
                  이름
                </label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  required={!isLogin}
                  className="w-full px-4 py-4 rounded-xl border-0 bg-blue-50 focus:outline-none focus:ring-2 focus:ring-[#00c288]/20 transition-all duration-200 text-[#111111] placeholder-[#9ca3af] shadow-sm"
                  placeholder="홍길동"
                />
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-[#111111] mb-2">
                이메일
              </label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                required
                className="w-full px-4 py-4 rounded-xl border-0 bg-white focus:outline-none focus:ring-2 focus:ring-[#00c288]/20 transition-all duration-200 text-[#111111] placeholder-[#9ca3af] shadow-sm"
                placeholder="example@email.com"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-[#111111] mb-2">
                비밀번호
              </label>
              <input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                required
                minLength={8}
                className="w-full px-4 py-4 rounded-xl border-0 bg-white focus:outline-none focus:ring-2 focus:ring-[#00c288]/20 transition-all duration-200 text-[#111111] placeholder-[#9ca3af] shadow-sm"
                placeholder="최소 8자 이상"
              />
              {!isLogin && (
                <p className="text-xs text-[#767676] mt-1">
                  비밀번호는 최소 8자 이상이며, 소문자와 숫자를 포함해야 합니다.
                </p>
              )}
            </div>

            {success && (
              <div className="bg-green-50/80 border-0 text-green-700 px-4 py-3 rounded-xl text-sm shadow-sm">
                {success}
              </div>
            )}

            {error && (
              <div className="bg-red-50/80 border-0 text-red-700 px-4 py-3 rounded-xl text-sm shadow-sm">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-[#00c288] text-white py-4 rounded-xl font-semibold hover:bg-[#00a876] hover:shadow-lg active:scale-[0.98] transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed relative z-10 border-0 outline-none"
              style={{
                background: loading ? '#9ca3af' : 'linear-gradient(90deg, #00c288 0%, #00a876 100%)',
                color: '#ffffff',
                fontWeight: '600'
              }}
            >
              <span className="relative z-10 text-white font-semibold">
                {loading ? '처리 중...' : isLogin ? '로그인' : '회원가입'}
              </span>
            </button>
          </form>

          {/* 전환 버튼 */}
          <div className="mt-8 text-center">
            <p className="text-[#9ca3af] text-sm mb-2">
              {isLogin ? '계정이 없으신가요?' : '이미 계정이 있으신가요?'}
            </p>
            <button
              onClick={() => {
                setIsLogin(!isLogin);
                setError('');
                setSuccess('');
              }}
              className="text-[#00c288] hover:text-[#00a876] font-medium text-sm transition-colors duration-200 underline-offset-4 hover:underline border-0 outline-none bg-transparent"
              style={{ border: 'none', outline: 'none', background: 'transparent' }}
            >
              {isLogin ? '회원가입' : '로그인'}
            </button>
          </div>
        </div>
        )}
      </div>
    </div>
  );
};
