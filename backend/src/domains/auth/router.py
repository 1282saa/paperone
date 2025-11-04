"""
Auth domain router - AWS Cognito 기반 인증
"""
import os
import boto3
from botocore.exceptions import ClientError
from fastapi import APIRouter, HTTPException, status

from .schemas import LoginRequest, RegisterRequest, TokenResponse

router = APIRouter()

# Cognito 클라이언트 초기화
cognito_client = boto3.client('cognito-idp', region_name=os.getenv('AWS_REGION', 'us-east-1'))

USER_POOL_ID = os.getenv('COGNITO_USER_POOL_ID', 'us-east-1_LBzH1bqb8')
CLIENT_ID = os.getenv('COGNITO_CLIENT_ID', '6avv0p8tgn757n8qpfdco8kdl6')


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest):
    """Cognito에 새 사용자 등록 (이메일 인증 필요)"""
    try:
        # Cognito에 사용자 생성
        response = cognito_client.sign_up(
            ClientId=CLIENT_ID,
            Username=request.email,
            Password=request.password,
            UserAttributes=[
                {'Name': 'email', 'Value': request.email},
                {'Name': 'name', 'Value': request.name},
            ]
        )

        return {
            "message": "회원가입이 완료되었습니다. 이메일로 전송된 인증 코드를 확인해주세요.",
            "user_sub": response['UserSub'],
            "email": request.email
        }

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'UsernameExistsException':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 등록된 이메일입니다."
            )
        elif error_code == 'InvalidPasswordException':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="비밀번호는 최소 8자 이상이며, 소문자와 숫자를 포함해야 합니다."
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"회원가입 실패: {e.response['Error']['Message']}"
            )


@router.post("/confirm", status_code=status.HTTP_200_OK)
async def confirm_sign_up(email: str, code: str):
    """이메일 인증 코드 확인"""
    try:
        cognito_client.confirm_sign_up(
            ClientId=CLIENT_ID,
            Username=email,
            ConfirmationCode=code
        )

        return {
            "message": "이메일 인증이 완료되었습니다. 로그인해주세요.",
            "email": email
        }

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'CodeMismatchException':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="인증 코드가 올바르지 않습니다."
            )
        elif error_code == 'ExpiredCodeException':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="인증 코드가 만료되었습니다. 재발송을 요청해주세요."
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"인증 실패: {e.response['Error']['Message']}"
            )


@router.post("/resend-code", status_code=status.HTTP_200_OK)
async def resend_confirmation_code(email: str):
    """인증 코드 재발송"""
    try:
        cognito_client.resend_confirmation_code(
            ClientId=CLIENT_ID,
            Username=email
        )

        return {
            "message": "인증 코드가 재발송되었습니다.",
            "email": email
        }

    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"코드 재발송 실패: {e.response['Error']['Message']}"
        )


@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest):
    """Cognito를 통한 로그인"""
    try:
        response = cognito_client.initiate_auth(
            ClientId=CLIENT_ID,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': request.email,
                'PASSWORD': request.password
            }
        )

        return TokenResponse(
            access_token=response['AuthenticationResult']['AccessToken'],
            id_token=response['AuthenticationResult']['IdToken'],
            refresh_token=response['AuthenticationResult']['RefreshToken']
        )

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'NotAuthorizedException':
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="이메일 또는 비밀번호가 올바르지 않습니다."
            )
        elif error_code == 'UserNotFoundException':
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="이메일 또는 비밀번호가 올바르지 않습니다."
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"로그인 실패: {e.response['Error']['Message']}"
            )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(refresh_token: str):
    """리프레시 토큰으로 새 액세스 토큰 발급"""
    try:
        response = cognito_client.initiate_auth(
            ClientId=CLIENT_ID,
            AuthFlow='REFRESH_TOKEN_AUTH',
            AuthParameters={
                'REFRESH_TOKEN': refresh_token
            }
        )

        return TokenResponse(
            access_token=response['AuthenticationResult']['AccessToken'],
            id_token=response['AuthenticationResult']['IdToken'],
            refresh_token=refresh_token  # 리프레시 토큰은 유지
        )

    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="토큰 갱신 실패"
        )
