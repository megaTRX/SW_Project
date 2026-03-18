from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database import get_db
from models import Conversation
from schemas import ConversationCreate, ConversationResponse
from typing import List

router = APIRouter()

# 대화 저장
@router.post("/", response_model=ConversationResponse)
async def create_conversation(data: ConversationCreate, db: AsyncSession = Depends(get_db)):
    conversation = Conversation(**data.model_dump())
    db.add(conversation)
    await db.commit()
    await db.refresh(conversation)
    return conversation

# 대화 전체 조회
@router.get("/", response_model=List[ConversationResponse])
async def get_conversations(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Conversation).order_by(Conversation.created_at))
    return result.scalars().all()

# 세션별 대화 조회
@router.get("/{session_id}", response_model=List[ConversationResponse])
async def get_conversation_by_session(session_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Conversation)
        .where(Conversation.session_id == session_id)
        .order_by(Conversation.created_at)
    )
    return result.scalars().all()