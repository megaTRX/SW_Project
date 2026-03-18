from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database import AsyncSessionLocal
from models import Medicine, Alert
from datetime import datetime

scheduler = AsyncIOScheduler()

async def check_medicine_alarms():
    """1분마다 실행 - 지금 시간이 복약 시간인지 확인"""
    now = datetime.now().strftime("%H:%M")  # 현재 시간 (예: "08:30")

    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Medicine))
        medicines = result.scalars().all()

        for medicine in medicines:
            alarm_times = medicine.alarm_times.split(",")  # "08:30,13:00" → ["08:30", "13:00"]
            
            if now in alarm_times:
                # 알림 DB에 저장
                alert = Alert(
                    type="복약알림",
                    message=f"{medicine.name} 드실 시간이에요! ({medicine.dose})",
                    is_resolved=False
                )
                db.add(alert)
        
        await db.commit()

def start_scheduler():
    # 매 1분마다 복약 시간 체크
    scheduler.add_job(
        check_medicine_alarms,
        CronTrigger(minute="*"),  # 매 분 실행
        id="medicine_alarm",
        replace_existing=True
    )
    scheduler.start()