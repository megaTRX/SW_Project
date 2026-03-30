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

# 멀티턴용 - 세션별 최근 대화 N개 조회
@router.get("/context/{session_id}")
async def get_conversation_context(
    session_id: str,
    limit: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Conversation)
        .where(Conversation.session_id == session_id)
        .order_by(Conversation.created_at.desc())
        .limit(limit)
    )
    items = result.scalars().all()
    items.reverse()  # 최신순으로 가져온 걸 다시 시간순으로

    # LLM에 바로 넣을 수 있는 형식으로 변환
    return {
        "session_id": session_id,
        "context": [
            {"role": item.role, "content": item.content}
            for item in items
        ]
    }