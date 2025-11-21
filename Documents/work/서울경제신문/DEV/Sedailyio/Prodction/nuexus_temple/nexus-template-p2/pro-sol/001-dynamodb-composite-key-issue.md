# DynamoDB Composite Key 문제 및 해결책

## 문제 상황

### 1. 증상
- 대화 저장은 되지만 대화 내용(메시지)이 표시되지 않음
- 사용자의 첫 메시지만 저장되고 AI 응답은 저장되지 않음
- 대화 제목 수정 시 "ValidationException: The provided key element does not match the schema" 오류 발생
- WebSocket 메시지 핸들러에서 동일한 ValidationException 오류 발생

### 2. 에러 로그
```
Error getting conversation history: An error occurred (ValidationException) when calling the GetItem operation: The provided key element does not match the schema
Error saving message: An error occurred (ValidationException) when calling the GetItem operation: The provided key element does not match the schema
```

## 문제 원인

### 1. 하드코딩된 테이블 이름
- **위치**: Repository 파일들
- **문제**: 이전 프로젝트(w1)의 테이블명이 하드코딩되어 있음
  - `w1-conversations-v2` → `f1-conversations-two`
  - `w1-prompts-v2` → `f1-prompts-two`
  - `w1-usage` → `f1-usage-two`

### 2. DynamoDB Composite Key 미사용
- **테이블 구조**: `userId` (파티션 키) + `conversationId` (정렬 키)
- **문제 코드**: `conversationId`만으로 조회 시도
```python
# 잘못된 코드
response = table.get_item(Key={'conversationId': conversation_id})

# 올바른 코드
response = table.get_item(Key={'userId': user_id, 'conversationId': conversation_id})
```

### 3. userId 없이 대화 생성
- **문제**: 새 대화 생성 시 userId가 선택적으로 추가됨
- **결과**: userId 없는 불완전한 대화 생성 → 이후 조회/업데이트 실패

## 해결 방법

### 1. Repository 파일 수정
**파일 경로**: `backend/src/repositories/`

#### conversation_repository.py
```python
# 수정 전
table_name = table_name or os.environ.get('CONVERSATIONS_TABLE', 'w1-conversations-v2')

# 수정 후
table_name = table_name or os.environ.get('CONVERSATIONS_TABLE', 'f1-conversations-two')
```

#### prompt_repository.py
```python
# 수정 전
self.table_name = table_name or os.environ.get('PROMPTS_TABLE', 'w1-prompts-v2')

# 수정 후
self.table_name = table_name or os.environ.get('PROMPTS_TABLE', 'f1-prompts-two')
```

#### usage_repository.py
```python
# 수정 전
self.table_name = table_name or os.environ.get('USAGE_TABLE', 'w1-usage')

# 수정 후
self.table_name = table_name or os.environ.get('USAGE_TABLE', 'f1-usage-two')
```

### 2. Composite Key 처리 로직 추가

#### conversation_repository.py - find_by_id 메서드
```python
def find_by_id(self, conversation_id: str, user_id: str = None) -> Optional[Conversation]:
    try:
        # user_id가 제공되지 않은 경우 스캔으로 찾기
        if not user_id:
            response = self.table.scan(
                FilterExpression='conversationId = :cid',
                ExpressionAttributeValues={':cid': conversation_id}
            )
            if response.get('Items'):
                return Conversation.from_dict(response['Items'][0])
            return None

        # user_id가 제공된 경우 직접 조회
        response = self.table.get_item(
            Key={
                'userId': user_id,
                'conversationId': conversation_id
            }
        )

        if 'Item' in response:
            return Conversation.from_dict(response['Item'])

        return None
    except Exception as e:
        logger.error(f"Error finding conversation by id: {str(e)}")
        raise
```

### 3. WebSocket Handler 수정

#### conversation_manager.py
```python
# 테이블명 수정
conversations_table = dynamodb.Table(os.environ.get('CONVERSATIONS_TABLE', 'f1-conversations-two'))

# save_message 메서드 수정 - userId 필수화
def save_message(conversation_id: str, role: str, content: str, engine_type: str = '11', user_id: str = None):
    # ... 코드 ...
    else:
        # 새 대화 생성 - userId는 필수
        if not user_id:
            logger.error(f"Cannot create conversation without userId for {conversation_id}")
            return False

        item = {
            'userId': user_id,  # 필수 키
            'conversationId': conversation_id,
            # ... 나머지 필드 ...
        }
        conversations_table.put_item(Item=item)
```

### 4. API Handler 수정

#### handlers/api/conversation.py - POST 메서드 개선
```python
# POST /conversations - 기존 대화가 있으면 메시지 업데이트
if conversation_id:
    existing = conversation_service.get_conversation(conversation_id)
    if existing:
        # 기존 대화가 있으면 메시지 업데이트
        logger.info(f"Conversation {conversation_id} exists, updating messages")

        if messages and len(messages) > 0:
            from src.models import Message
            message_objects = []
            for msg in messages:
                message_objects.append(Message(
                    role=msg.get('type', msg.get('role', 'user')),  # type을 role로 매핑
                    content=msg.get('content'),
                    timestamp=msg.get('timestamp'),
                    metadata=msg.get('metadata', {})
                ))

            success = conversation_service.repository.update_messages(
                conversation_id,
                message_objects
            )
```

## 적용 방법

### 1. Lambda 함수 재배포
```bash
# API Lambda 배포
cd backend
zip -r lambda-conversation.zip . -x "*.pyc" -x "__pycache__/*" -x ".git/*" -x "venv/*" -x ".env" -x ".DS_Store" -x "*.zip"
aws lambda update-function-code --function-name f1-conversation-api-two --zip-file fileb://lambda-conversation.zip --region us-east-1

# WebSocket Lambda 배포
zip -r lambda-websocket.zip . -x "*.pyc" -x "__pycache__/*" -x ".git/*" -x "venv/*" -x ".env" -x ".DS_Store" -x "*.zip"
aws lambda update-function-code --function-name f1-websocket-message-two --zip-file fileb://lambda-websocket.zip --region us-east-1
```

### 2. 배포 확인
```bash
# Lambda 상태 확인
aws lambda get-function --function-name f1-conversation-api-two --region us-east-1 --query 'Configuration.LastUpdateStatus'
aws lambda get-function --function-name f1-websocket-message-two --region us-east-1 --query 'Configuration.LastUpdateStatus'
```

## 검증 방법

### 1. DynamoDB 데이터 확인
```bash
# 대화 메시지 개수 확인
aws dynamodb scan --table-name f1-conversations-two --region us-east-1 --output json | \
  jq '.Items[] | {conversationId: .conversationId.S, messageCount: (.messages.L | length)}'
```

### 2. 새 대화 테스트
1. 프론트엔드에서 새 대화 시작
2. 사용자 메시지 전송
3. AI 응답 확인
4. 대화 스레드 재진입 시 전체 대화 내용 표시 확인

## 예방책

### 1. 환경 변수 사용
- 하드코딩 대신 환경 변수 활용
- `.env` 파일로 환경별 설정 관리

### 2. 템플릿 변수화
- 스크립트에서 SERVICE_PREFIX 변수 사용
- 프로젝트 생성 시 자동 치환

### 3. 테스트 자동화
- DynamoDB 키 스키마 검증 테스트
- Lambda 함수 단위 테스트 추가

## 관련 파일 목록

1. `/backend/src/repositories/conversation_repository.py`
2. `/backend/src/repositories/prompt_repository.py`
3. `/backend/src/repositories/usage_repository.py`
4. `/backend/handlers/api/conversation.py`
5. `/backend/handlers/websocket/conversation_manager.py`
6. `/backend/services/websocket_service.py`

## 수정 날짜
- 2025-09-25
- 작업자: Claude & 사용자
- 프로젝트: nexus-template-v2 (f1 서비스)