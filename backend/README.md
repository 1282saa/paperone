# 오늘 한 장 Backend - FastAPI + AWS Serverless

학습 관리 및 백지복습 플랫폼 백엔드 - FastAPI + AWS Lambda + API Gateway + Bedrock

## 📁 프로젝트 구조

```
sw_backend/
├── alembic/              # DB 마이그레이션
├── src/
│   ├── core/            # 핵심 설정 (config, database, security)
│   ├── dependencies.py  # 공통 의존성 (인증 등)
│   ├── main.py          # FastAPI 앱 진입점
│   ├── lambda_handler.py # AWS Lambda 핸들러
│   └── domains/         # 도메인별 모듈
│       ├── auth/        # 인증 (로그인/회원가입)
│       ├── users/       # 사용자 프로필
│       ├── learning/    # 백지복습, 학습 세션
│       ├── todo/        # 오늘의 할 일
│       ├── calendar/    # D-Day, 학습 일정
│       ├── statistics/  # 학습 통계
│       └── ai/          # AI 문제 생성, AI 튜터
├── tests/               # 테스트 코드
├── requirements.txt     # Python 의존성
├── serverless.yml       # Serverless Framework 설정
└── .env.example         # 환경변수 예시
```

## 🚀 시작하기

### 1. 환경 설정

```bash
# Python 가상환경 생성
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 환경변수 설정
cp .env.example .env
# .env 파일을 열어 필요한 값들을 설정하세요
```

### 2. 데이터베이스 마이그레이션

```bash
# 마이그레이션 생성
alembic revision --autogenerate -m "Initial migration"

# 마이그레이션 적용
alembic upgrade head
```

### 3. 로컬 개발 서버 실행

```bash
# Uvicorn으로 로컬 서버 실행
uvicorn src.main:app --reload --port 8000

# API 문서 확인
# http://localhost:8000/docs (Swagger UI)
# http://localhost:8000/redoc (ReDoc)
```

## 📦 AWS Lambda 배포

### Serverless Framework 사용

```bash
# Serverless Framework 설치
npm install -g serverless
npm install --save-dev serverless-python-requirements

# 배포
serverless deploy

# 특정 스테이지 배포
serverless deploy --stage prod

# 로그 확인
serverless logs -f api --tail
```

## 🔑 주요 기능

### 1. 인증 (Auth)
- `POST /api/v1/auth/login` - 로그인
- `POST /api/v1/auth/register` - 회원가입

### 2. 사용자 (Users)
- `GET /api/v1/users/me` - 현재 사용자 정보
- `PATCH /api/v1/users/me/profile` - 프로필 업데이트

### 3. 학습/백지복습 (Learning)
- 과목 관리
- 학습 세션 기록
- 백지 복습 생성 및 관리

### 4. 오늘의 할 일 (Todo)
- 일별 할 일 관리
- 완료 상태 추적

### 5. 캘린더/D-Day (Calendar)
- D-Day 목표 설정 (수능 카운트다운 등)
- 학습 일정 관리

### 6. 학습 통계 (Statistics)
- `GET /api/v1/statistics/home` - 홈 화면 통계
  - 현재 연속 학습 일수
  - 복습 지속률 (최근 7일)
  - 오늘의 할 일 개수
  - D-Day 정보
- 일별/주간 학습 통계

### 7. AI 기능 (AI)
- AI 문제 생성 (AWS Bedrock)
- AI 튜터 복습이 (대화형 학습)

## 🛠 기술 스택

- **Framework**: FastAPI 0.109.0
- **Database**: PostgreSQL (AWS RDS) + SQLAlchemy (async)
- **Authentication**: JWT (python-jose)
- **AI**: AWS Bedrock (Claude 3)
- **Deployment**: AWS Lambda + API Gateway
- **Task Queue**: ARQ + Redis (옵션)
- **Testing**: Pytest

## 📝 환경변수

`.env.example` 참고:

```
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/db
SECRET_KEY=your-secret-key-min-32-chars
BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0
AWS_REGION=us-east-1
```

## 🎨 API 엔드포인트

### 홈 화면 데이터
```
GET /api/v1/statistics/home
```

응답 예시:
```json
{
  "current_streak": 5,
  "total_study_days": 42,
  "weekly_consistency_rate": 0.82,
  "today_tasks_count": 4,
  "dday_info": {
    "title": "수능",
    "days_remaining": 297
  }
}
```

## 🧪 테스트

```bash
# 전체 테스트 실행
pytest

# 커버리지 포함
pytest --cov=src tests/

# 특정 도메인 테스트
pytest tests/domains/test_learning.py
```

## 📚 API 문서

배포 후:
- Swagger UI: `https://your-api-gateway-url/docs`
- ReDoc: `https://your-api-gateway-url/redoc`

## 🔐 보안

- JWT 기반 인증
- 비밀번호 bcrypt 해싱
- CORS 설정
- AWS IAM 역할 기반 권한

## 📄 데이터베이스 모델

### 주요 테이블
- `users` - 사용자 기본 정보
- `user_profiles` - 학교, 학과, 구독 정보, 학습 통계
- `subjects` - 과목
- `learning_sessions` - 학습 세션 기록
- `blank_sheets` - 백지 복습 시트
- `daily_tasks` - 오늘의 할 일
- `ddays` - D-Day 목표
- `daily_statistics` - 일별 학습 통계
- `ai_generated_questions` - AI 생성 문제
- `ai_tutor_conversations` - AI 튜터 대화 기록

## 📄 라이선스

Proprietary
