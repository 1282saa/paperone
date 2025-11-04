"""
FastAPI main application - 오늘 한 장 학습 플랫폼
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .core.config import settings
from .domains.auth.router import router as auth_router
from .domains.users.router import router as users_router
from .domains.learning.router import router as learning_router
from .domains.todo.router import router as todo_router
from .domains.calendar.router import router as calendar_router
from .domains.statistics.router import router as statistics_router
from .domains.ai.router import router as ai_router
from .domains.subjects.router import router as subjects_router

# Create FastAPI app
app = FastAPI(
    title="오늘 한 장 API",
    version=settings.VERSION,
    debug=settings.DEBUG,
    docs_url="/docs",
    redoc_url="/redoc",
    description="학습 관리 및 백지복습 플랫폼 API",
)

# CORS middleware
# 프로덕션에서는 모든 오리진 허용 (나중에 특정 도메인으로 제한 가능)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 모든 오리진 허용
    allow_credentials=False,  # credentials는 allow_origins=["*"]와 함께 사용 불가
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "version": settings.VERSION, "app": "오늘 한 장"}


# Include routers
app.include_router(auth_router, prefix="/api/v1/auth", tags=["인증"])
app.include_router(users_router, prefix="/api/v1/users", tags=["사용자"])
app.include_router(subjects_router, prefix="/api/v1/subjects", tags=["과목/문서"])
app.include_router(learning_router, prefix="/api/v1/learning", tags=["학습/백지복습"])
app.include_router(todo_router, prefix="/api/v1/tasks", tags=["오늘의 할 일"])
app.include_router(calendar_router, prefix="/api/v1/calendar", tags=["캘린더/D-Day"])
app.include_router(statistics_router, prefix="/api/v1/statistics", tags=["학습 통계"])
app.include_router(ai_router, prefix="/api/v1/ai", tags=["AI 기능"])


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
