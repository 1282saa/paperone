#!/bin/bash

# 빠른 배포 스크립트
# 사용법: ./quick-deploy.sh [서비스명] [리전]

SERVICE_NAME=${1:-tem1}
REGION=${2:-us-east-1}

echo "🚀 $SERVICE_NAME 서비스 배포 시작"

# 1. 환경변수 파일 생성
echo "📝 환경변수 파일 생성 중..."

# Backend .env 생성
sed "s/SERVICE_NAME/$SERVICE_NAME/g" ../backend/.env.template > ../backend/.env
echo "✅ Backend .env 생성 완료"

# Frontend .env 생성 (임시)
cp ../frontend/.env.template ../frontend/.env
echo "✅ Frontend .env 생성 완료 (API ID는 나중에 업데이트)"

# 2. Phase 1 실행
echo "🏗️ Phase 1: 인프라 구축..."
./deploy-phase1-infra.sh "$SERVICE_NAME" "$REGION"

# 3. API ID 추출 및 Frontend .env 업데이트
if [ -f "../.api-ids" ]; then
    source ../.api-ids

    if [ -n "$REST_API_ID" ] && [ -n "$WS_API_ID" ]; then
        echo "📝 Frontend .env 업데이트 중..."

        # macOS와 Linux 호환
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/YOUR_API_ID/$REST_API_ID/g" ../frontend/.env
            sed -i '' "s/YOUR_WS_API_ID/$WS_API_ID/g" ../frontend/.env
        else
            # Linux
            sed -i "s/YOUR_API_ID/$REST_API_ID/g" ../frontend/.env
            sed -i "s/YOUR_WS_API_ID/$WS_API_ID/g" ../frontend/.env
        fi

        echo "✅ API ID 업데이트 완료"
    fi
fi

# 4. Phase 2 실행
echo "📦 Phase 2: 코드 배포..."
./deploy-phase2-code.sh "$SERVICE_NAME" "$REGION"

# 5. 결과 출력
echo ""
echo "🎉 배포 완료!"
echo ""

if [ -f "../.cloudfront-url" ]; then
    CLOUDFRONT_URL=$(cat ../.cloudfront-url)
    echo "🌐 프론트엔드 URL: $CLOUDFRONT_URL"
fi

if [ -n "$REST_API_ID" ]; then
    echo "🔌 REST API: https://$REST_API_ID.execute-api.$REGION.amazonaws.com/prod"
fi

if [ -n "$WS_API_ID" ]; then
    echo "🔌 WebSocket: wss://$WS_API_ID.execute-api.$REGION.amazonaws.com/prod"
fi

echo ""
echo "다음 단계:"
echo "1. 브라우저에서 프론트엔드 URL 접속"
echo "2. 개발자 콘솔에서 네트워크 확인"
echo "3. CloudWatch 로그 모니터링"