#!/bin/bash

# SSO 쿠키 테스트 스크립트
# 사용법:
# 1. 브라우저에서 n1.sedaily.ai 로그인
# 2. DevTools → Application → Cookies → sso_id_token, sso_access_token 복사
# 3. 아래 변수에 붙여넣기
# 4. ./test-sso.sh 실행

# ========== 여기에 쿠키 값 입력 ==========
SSO_ID_TOKEN="여기에_id_token_붙여넣기"
SSO_ACCESS_TOKEN="여기에_access_token_붙여넣기"
# ========================================

# 테스트할 API 엔드포인트
API_ENDPOINT="https://b1api.sedaily.ai/api/conversations"

echo "======================================"
echo "SSO 쿠키 테스트"
echo "======================================"
echo ""
echo "테스트 대상: $API_ENDPOINT"
echo ""

# 쿠키 값 확인
if [ "$SSO_ID_TOKEN" = "여기에_id_token_붙여넣기" ]; then
    echo "❌ 오류: SSO_ID_TOKEN을 설정해주세요"
    echo ""
    echo "방법:"
    echo "1. 브라우저에서 https://n1.sedaily.ai 접속 및 로그인"
    echo "2. DevTools (F12) → Application → Cookies → n1.sedaily.ai"
    echo "3. sso_id_token 값 복사"
    echo "4. 이 스크립트의 SSO_ID_TOKEN 변수에 붙여넣기"
    exit 1
fi

echo "쿠키로 API 호출 중..."
echo ""

# API 호출 (쿠키 헤더 포함)
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Cookie: sso_id_token=$SSO_ID_TOKEN; sso_access_token=$SSO_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "$API_ENDPOINT")

# HTTP 상태 코드 추출
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "HTTP 상태 코드: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 성공: SSO 인증이 정상 작동합니다"
    echo ""
    echo "응답 본문:"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
elif [ "$HTTP_CODE" = "401" ]; then
    echo "❌ 실패: 인증 오류 (401 Unauthorized)"
    echo ""
    echo "가능한 원인:"
    echo "- 쿠키 값이 잘못되었거나 만료됨"
    echo "- 백엔드에서 쿠키를 읽지 못함"
    echo ""
    echo "응답 본문:"
    echo "$BODY"
else
    echo "⚠️  예상치 못한 상태 코드: $HTTP_CODE"
    echo ""
    echo "응답 본문:"
    echo "$BODY"
fi

echo ""
echo "======================================"
