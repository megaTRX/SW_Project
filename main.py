from fastapi import FastAPI
from database import engine, Base
from routers import chat, medicine, schedule, alert, auth
from scheduler import start_scheduler

app = FastAPI(title="노인케어 챗봇 백엔드")

# 서버 시작할 때 DB 테이블 자동 생성 + 스케줄러 시작
@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    start_scheduler()

# 서버 끌 때 스케줄러 종료
@app.on_event("shutdown")
async def shutdown():
    from scheduler import scheduler
    scheduler.shutdown()

# 라우터 연결
app.include_router(auth.router, prefix="/auth", tags=["인증"])
app.include_router(chat.router, prefix="/chat", tags=["대화 로그"])
app.include_router(medicine.router, prefix="/medicine", tags=["복약 관리"])
app.include_router(schedule.router, prefix="/schedule", tags=["일정 관리"])
app.include_router(alert.router, prefix="/alert", tags=["위급 알림"])

@app.get("/")
async def root():
    return {"status": "ok", "message": "노인케어 챗봇 백엔드 실행중 🤖"}