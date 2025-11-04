import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { Screen } from './screens/Screen';
import { LoginScreen } from './screens/LoginScreen';
import { isAuthenticated } from './services/authApi';

// Protected Route 컴포넌트
const ProtectedRoute = ({ children }) => {
  const isLoggedIn = isAuthenticated();

  if (!isLoggedIn) {
    return <Navigate to="/login" replace />;
  }

  return children;
};

// Auth Wrapper 컴포넌트
const AuthWrapper = () => {
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // 초기 로그인 상태 확인
    const checkAuth = () => {
      const loggedIn = isAuthenticated();
      if (loggedIn) {
        // 이미 로그인된 경우 메인 페이지로
        if (window.location.pathname === '/login') {
          navigate('/');
        }
      }
      setIsLoading(false);
    };

    checkAuth();
  }, [navigate]);

  const handleLoginSuccess = () => {
    navigate('/');
  };

  const handleLogout = () => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('id_token');
    localStorage.removeItem('refresh_token');
    navigate('/login');
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#f1f3f5] flex items-center justify-center">
        <div className="text-center">
          <div className="text-2xl text-[#767676]">로딩 중...</div>
        </div>
      </div>
    );
  }

  return (
    <Routes>
      <Route path="/login" element={<LoginScreen onLoginSuccess={handleLoginSuccess} />} />
      <Route
        path="/*"
        element={
          <ProtectedRoute>
            <Screen onLogout={handleLogout} />
          </ProtectedRoute>
        }
      />
    </Routes>
  );
};

export const App = () => {
  return (
    <BrowserRouter>
      <AuthWrapper />
    </BrowserRouter>
  );
};
