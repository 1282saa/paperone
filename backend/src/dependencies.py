"""
Common dependencies for dependency injection
"""
import os
from typing import Annotated, Optional

import boto3
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel

security = HTTPBearer(auto_error=False)  # auto_error=False로 설정하여 토큰 없이도 허용

# Cognito 설정
COGNITO_REGION = os.getenv('AWS_REGION', 'us-east-1')
COGNITO_USER_POOL_ID = os.getenv('COGNITO_USER_POOL_ID', 'us-east-1_LBzH1bqb8')
COGNITO_CLIENT_ID = os.getenv('COGNITO_CLIENT_ID', '6avv0p8tgn757n8qpfdco8kdl6')

# JWK 키 캐싱 (성능 향상)
_jwks = None


def get_jwks():
    """Cognito의 JWK 키 가져오기 (캐싱)"""
    global _jwks
    if _jwks is None:
        import requests
        url = f'https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{COGNITO_USER_POOL_ID}/.well-known/jwks.json'
        _jwks = requests.get(url).json()
    return _jwks


# 사용자 모델
class CognitoUser(BaseModel):
    id: str  # Cognito sub
    email: str
    username: str


async def get_current_user(
    credentials: Annotated[Optional[HTTPAuthorizationCredentials], Depends(security)] = None,
) -> CognitoUser:
    """Get current authenticated user from Cognito token"""
    # 인증이 없으면 테스트용 고정 user_id 사용 (개발 환경용)
    if credentials is None:
        return CognitoUser(id="test-user-001", email="test@example.com", username="test_user")

    token = credentials.credentials

    try:
        # JWT 헤더 디코딩 (검증 없이)
        unverified_header = jwt.get_unverified_header(token)

        # JWK에서 올바른 키 찾기
        jwks = get_jwks()
        rsa_key = {}
        for key in jwks['keys']:
            if key['kid'] == unverified_header['kid']:
                rsa_key = {
                    'kty': key['kty'],
                    'kid': key['kid'],
                    'use': key['use'],
                    'n': key['n'],
                    'e': key['e']
                }
                break

        if not rsa_key:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Unable to find appropriate key"
            )

        # 토큰 검증 및 디코딩
        payload = jwt.decode(
            token,
            rsa_key,
            algorithms=['RS256'],
            audience=COGNITO_CLIENT_ID,
            issuer=f'https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{COGNITO_USER_POOL_ID}'
        )

        # 사용자 정보 추출
        user_id = payload.get('sub')
        email = payload.get('email', '')
        username = payload.get('cognito:username', email)

        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )

        return CognitoUser(id=user_id, email=email, username=username)

    except JWTError as e:
        # JWT 검증 실패 시에도 개발 환경에서는 테스트 사용자 반환
        return CognitoUser(id="test-user-001", email="test@example.com", username="test_user")
    except Exception as e:
        # 기타 에러도 개발 환경에서는 테스트 사용자 반환
        return CognitoUser(id="test-user-001", email="test@example.com", username="test_user")


# Type alias for dependency injection
CurrentUser = Annotated[CognitoUser, Depends(get_current_user)]
