#!/bin/bash

# 카드 개수 기반 네이밍으로 마이그레이션
# two = 2개 카드 (비즈니스, 종합뉴스)
# three = 3개 카드
# five = 5개 카드

SERVICE_NAME="w1"
CARD_COUNT="two"  # 현재는 2개 카드 시스템
REGION="us-east-1"

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 1. 새로운 테이블 생성
create_new_tables() {
    log_info "Creating new tables with card-based naming..."

    # Conversations table
    log_info "Creating ${SERVICE_NAME}-conversations-${CARD_COUNT} table..."
    aws dynamodb create-table \
        --table-name "${SERVICE_NAME}-conversations-${CARD_COUNT}" \
        --attribute-definitions \
            AttributeName=userId,AttributeType=S \
            AttributeName=conversationId,AttributeType=S \
            AttributeName=createdAt,AttributeType=S \
        --key-schema \
            AttributeName=userId,KeyType=HASH \
            AttributeName=conversationId,KeyType=RANGE \
        --global-secondary-indexes \
            "IndexName=ConversationsByDate,Keys=[{AttributeName=userId,KeyType=HASH},{AttributeName=createdAt,KeyType=RANGE}],Projection={ProjectionType=ALL},BillingMode=PAY_PER_REQUEST" \
        --billing-mode PAY_PER_REQUEST \
        --region $REGION 2>/dev/null || log_warning "Conversations table already exists or error occurred"

    # Prompts table
    log_info "Creating ${SERVICE_NAME}-prompts-${CARD_COUNT} table..."
    aws dynamodb create-table \
        --table-name "${SERVICE_NAME}-prompts-${CARD_COUNT}" \
        --attribute-definitions \
            AttributeName=engineType,AttributeType=S \
            AttributeName=promptId,AttributeType=S \
        --key-schema \
            AttributeName=engineType,KeyType=HASH \
            AttributeName=promptId,KeyType=RANGE \
        --billing-mode PAY_PER_REQUEST \
        --region $REGION 2>/dev/null || log_warning "Prompts table already exists or error occurred"

    # Usage table
    log_info "Creating ${SERVICE_NAME}-usage-${CARD_COUNT} table..."
    aws dynamodb create-table \
        --table-name "${SERVICE_NAME}-usage-${CARD_COUNT}" \
        --attribute-definitions \
            AttributeName=userId,AttributeType=S \
            AttributeName=date,AttributeType=S \
        --key-schema \
            AttributeName=userId,KeyType=HASH \
            AttributeName=date,KeyType=RANGE \
        --billing-mode PAY_PER_REQUEST \
        --region $REGION 2>/dev/null || log_warning "Usage table already exists or error occurred"
}

# 2. 데이터 마이그레이션
migrate_data() {
    log_info "Starting data migration..."

    # Conversations 마이그레이션
    log_info "Migrating conversations data..."
    aws dynamodb scan --table-name "${SERVICE_NAME}-conversations-v2" --region $REGION > /tmp/conversations-backup.json

    if [ -s /tmp/conversations-backup.json ]; then
        jq -c '.Items[]' /tmp/conversations-backup.json | while read item; do
            aws dynamodb put-item \
                --table-name "${SERVICE_NAME}-conversations-${CARD_COUNT}" \
                --item "$item" \
                --region $REGION
        done
        log_info "Conversations data migrated successfully"
    fi

    # Prompts 마이그레이션
    log_info "Migrating prompts data..."
    aws dynamodb scan --table-name "${SERVICE_NAME}-prompts-v2" --region $REGION > /tmp/prompts-backup.json

    if [ -s /tmp/prompts-backup.json ]; then
        jq -c '.Items[]' /tmp/prompts-backup.json | while read item; do
            aws dynamodb put-item \
                --table-name "${SERVICE_NAME}-prompts-${CARD_COUNT}" \
                --item "$item" \
                --region $REGION
        done
        log_info "Prompts data migrated successfully"
    fi

    # Usage 마이그레이션
    log_info "Migrating usage data..."
    aws dynamodb scan --table-name "${SERVICE_NAME}-usage-v2" --region $REGION > /tmp/usage-backup.json

    if [ -s /tmp/usage-backup.json ]; then
        jq -c '.Items[]' /tmp/usage-backup.json | while read item; do
            aws dynamodb put-item \
                --table-name "${SERVICE_NAME}-usage-${CARD_COUNT}" \
                --item "$item" \
                --region $REGION
        done
        log_info "Usage data migrated successfully"
    fi
}

# 3. Lambda 환경 변수 업데이트
update_lambda_env() {
    log_info "Updating Lambda environment variables..."

    # API Lambda
    aws lambda update-function-configuration \
        --function-name "${SERVICE_NAME}-api-lambda" \
        --environment "Variables={
            CONVERSATIONS_TABLE=${SERVICE_NAME}-conversations-${CARD_COUNT},
            PROMPTS_TABLE=${SERVICE_NAME}-prompts-${CARD_COUNT},
            USAGE_TABLE=${SERVICE_NAME}-usage-${CARD_COUNT}
        }" \
        --region $REGION > /dev/null

    log_info "API Lambda environment updated"

    # WebSocket Lambda
    aws lambda update-function-configuration \
        --function-name "${SERVICE_NAME}-websocket-lambda" \
        --environment "Variables={
            CONVERSATIONS_TABLE=${SERVICE_NAME}-conversations-${CARD_COUNT},
            PROMPTS_TABLE=${SERVICE_NAME}-prompts-${CARD_COUNT},
            USAGE_TABLE=${SERVICE_NAME}-usage-${CARD_COUNT}
        }" \
        --region $REGION > /dev/null

    log_info "WebSocket Lambda environment updated"
}

# 4. 백엔드 코드 업데이트
update_backend_code() {
    log_info "Updating backend code with new table names..."

    # 백엔드 파일들에서 -v2를 -two로 변경
    find ../backend -type f -name "*.py" -exec sed -i '' \
        -e "s/${SERVICE_NAME}-conversations-v2/${SERVICE_NAME}-conversations-${CARD_COUNT}/g" \
        -e "s/${SERVICE_NAME}-prompts-v2/${SERVICE_NAME}-prompts-${CARD_COUNT}/g" \
        -e "s/${SERVICE_NAME}-usage-v2/${SERVICE_NAME}-usage-${CARD_COUNT}/g" {} \;

    log_info "Backend code updated"
}

# 5. 프론트엔드 설정 업데이트 (필요한 경우)
update_frontend_config() {
    log_info "Frontend doesn't directly reference table names, skipping..."
}

# 메인 실행
main() {
    log_info "Starting migration to card-based naming convention..."
    log_info "Service: ${SERVICE_NAME}, Card Count: ${CARD_COUNT}"

    read -p "This will create new tables and migrate data. Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Migration cancelled"
        exit 1
    fi

    create_new_tables

    log_info "Waiting for tables to be active..."
    sleep 10

    migrate_data
    update_lambda_env
    update_backend_code

    log_info "Migration completed successfully!"
    log_warning "Please verify the application is working correctly before deleting old tables"
    log_warning "Old tables (-v2) have been preserved for rollback if needed"
}

main