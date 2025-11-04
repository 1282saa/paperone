"""
AI service - OpenAI chatbot with SQLite
"""
from typing import List
from uuid import uuid4

from openai import AsyncOpenAI
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ...core.config import settings
from .models import AITutorConversation
from .schemas import AITutorRequest, AITutorResponse


class AIService:
    """AI tutor service"""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        self.model = settings.OPENAI_MODEL

    async def chat_with_tutor(
        self, user_id: str, request: AITutorRequest
    ) -> AITutorResponse:
        """Chat with AI tutor"""

        # Generate or reuse conversation ID
        conversation_id = request.conversation_id or str(uuid4())

        # Get conversation history (last 10 messages)
        conversation_history = await self._get_conversation_history(
            user_id, conversation_id, limit=10
        )

        # Build messages for OpenAI API
        messages = self._build_messages(conversation_history, request.message)

        # Call OpenAI API
        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                temperature=0.7,
                max_tokens=1000,
            )

            assistant_message = response.choices[0].message.content
            total_tokens = response.usage.total_tokens

            # Save user message
            await self._save_message(
                user_id=user_id,
                conversation_id=conversation_id,
                role="user",
                message=request.message,
            )

            # Save AI response
            await self._save_message(
                user_id=user_id,
                conversation_id=conversation_id,
                role="assistant",
                message=assistant_message,
                token_count=total_tokens,
            )

            return AITutorResponse(
                message=assistant_message, conversation_id=conversation_id
            )

        except Exception as e:
            raise Exception(f"OpenAI API call failed: {str(e)}")

    async def _get_conversation_history(
        self, user_id: str, conversation_id: str, limit: int = 10
    ) -> List[AITutorConversation]:
        """Get conversation history from database"""
        stmt = (
            select(AITutorConversation)
            .where(
                AITutorConversation.user_id == user_id,
                AITutorConversation.conversation_id == conversation_id,
            )
            .order_by(AITutorConversation.created_at.desc())
            .limit(limit)
        )

        result = await self.db.execute(stmt)
        conversations = result.scalars().all()

        return list(reversed(conversations))  # Return in chronological order

    def _build_messages(
        self, history: List[AITutorConversation], new_message: str
    ) -> List[dict]:
        """Build messages for OpenAI"""
        messages = [
            {
                "role": "system",
                "content": """You are a kind and helpful learning assistant.
Please answer students' questions clearly and in an easy-to-understand manner.
Rather than simply giving answers, explain in a way that helps students understand on their own.
When necessary, provide examples and offer encouragement and support.""",
            }
        ]

        # Add previous conversations
        for conv in history:
            messages.append({"role": conv.role, "content": conv.message})

        # Add new message
        messages.append({"role": "user", "content": new_message})

        return messages

    async def _save_message(
        self,
        user_id: str,
        conversation_id: str,
        role: str,
        message: str,
        token_count: int | None = None,
    ):
        """Save message to database"""
        conversation = AITutorConversation(
            user_id=user_id,
            conversation_id=conversation_id,
            role=role,
            message=message,
            token_count=token_count,
        )

        self.db.add(conversation)
        await self.db.commit()
        await self.db.refresh(conversation)

    async def get_user_conversations(self, user_id: str) -> List[dict]:
        """Get user's conversation list (grouped by conversation_id)"""
        stmt = (
            select(AITutorConversation)
            .where(AITutorConversation.user_id == user_id)
            .order_by(AITutorConversation.created_at.desc())
        )

        result = await self.db.execute(stmt)
        conversations = result.scalars().all()

        # Group by conversation_id
        conversation_dict = {}
        for conv in conversations:
            conv_id = conv.conversation_id
            if conv_id not in conversation_dict:
                conversation_dict[conv_id] = {
                    "conversation_id": conv_id,
                    "first_message": conv.message[:100],
                    "created_at": conv.created_at.isoformat(),
                    "message_count": 0,
                }
            conversation_dict[conv_id]["message_count"] += 1

        return list(conversation_dict.values())

    async def get_conversation_detail(
        self, user_id: str, conversation_id: str
    ) -> List[dict]:
        """Get full conversation detail"""
        conversations = await self._get_conversation_history(
            user_id, conversation_id, limit=100
        )

        return [
            {
                "role": conv.role,
                "message": conv.message,
                "created_at": conv.created_at.isoformat(),
                "token_count": conv.token_count,
            }
            for conv in conversations
        ]
