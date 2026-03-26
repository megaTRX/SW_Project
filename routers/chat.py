from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
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

# 대화 전체 조회 (페이지네이션)
@router.get("/", response_model=dict)
async def get_conversations(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db)
):
    offset = (page - 1) * size

    # 전체 개수
    count_result = await db.execute(select(func.count(Conversation.id)))
    total = count_result.scalar()

    # 페이지 데이터
    result = await db.execute(
        select(Conversation)
        .order_by(Conversation.created_at.desc())
        .offset(offset)
        .limit(size)
    )
    items = result.scalars().all()

    return {
        "total": total,
        "page": page,
        "size": size,
        "total_pages": (total + size - 1) // size,
        "items": items
    }

# 세션별 대화 조회
@router.get("/{session_id}", response_model=List[ConversationResponse])
async def get_conversation_by_session(session_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Conversation)
        .where(Conversation.session_id == session_id)
        .order_by(Conversation.created_at)
    )
    return result.scalars().all()