"""
Initialize database - Create tables
"""
import asyncio

from src.core.database import Base, engine, init_db
from src.domains.ai.models import AITutorConversation


async def create_tables():
    """Create all tables"""
    print("Creating database tables...")

    async with engine.begin() as conn:
        # Drop all tables (for development)
        await conn.run_sync(Base.metadata.drop_all)
        # Create all tables
        await conn.run_sync(Base.metadata.create_all)

    print("✅ Database tables created successfully!")
    print(f"Tables: {list(Base.metadata.tables.keys())}")


if __name__ == "__main__":
    asyncio.run(create_tables())
