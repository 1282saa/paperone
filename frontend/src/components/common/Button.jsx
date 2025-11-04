/**
 * Button Component
 * 재사용 가능한 버튼 컴포넌트
 */

import React from 'react';

export const Button = ({
  children,
  variant = "primary", // primary, secondary, danger
  size = "md", // sm, md, lg
  onClick,
  disabled = false,
  type = "button",
  className = ""
}) => {
  const baseClasses = "rounded-2xl transition-colors border-0 cursor-pointer [font-family:'Pretendard-SemiBold',Helvetica] font-semibold";

  const variantClasses = {
    primary: "bg-[#00c288] hover:bg-[#00a876] text-white",
    secondary: "bg-[#e0e0e0] hover:bg-[#d0d0d0] text-[#505050]",
    danger: "bg-[#ff6b6b] hover:bg-[#ff5252] text-white"
  };

  const sizeClasses = {
    sm: "h-8 px-3 text-sm",
    md: "h-12 px-4 text-base",
    lg: "h-14 px-6 text-lg"
  };

  const disabledClasses = disabled ? "opacity-50 cursor-not-allowed" : "";

  const classes = `${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${disabledClasses} ${className}`.trim();

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={classes}
    >
      {children}
    </button>
  );
};