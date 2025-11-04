"""
ARQ worker for background tasks (optional)
"""
from arq import create_pool
from arq.connections import RedisSettings

from .core.config import settings


async def sample_task(ctx):
    """Sample background task"""
    print("Sample task executed")
    return {"status": "completed"}


class WorkerSettings:
    """ARQ worker settings"""

    functions = [sample_task]
    redis_settings = RedisSettings.from_dsn(settings.REDIS_URL)
