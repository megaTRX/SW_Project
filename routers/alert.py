from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database import get_db
from models import Alert
from schemas import AlertCreate, AlertResponse
from typing import List

router = APIRouter()

# 알림 추가
@router.post("/", response_model=AlertResponse)
async def create_alert(data: AlertCreate, db: AsyncSession = Depends(get_db)):
    alert = Alert(**data.model_dump())
    db.add(alert)
    await db.commit()
    await db.refresh(alert)
    return alert

# 알림 전체 조회
@router.get("/", response_model=List[AlertResponse])
async def get_alerts(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Alert).order_by(Alert.created_at))
    return result.scalars().all()

# 알림 해결 처리
@router.patch("/{alert_id}/resolve")
async def resolve_alert(alert_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Alert).where(Alert.id == alert_id))
    alert = result.scalar_one_or_none()
    if alert:
        alert.is_resolved = True
        await db.commit()
    return {"message": "알림 해결 처리됨"}