from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from database import Base

# 대화 로그 테이블
class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, index=True)       # 대화 세션 구분
    role = Column(String)                          # "user" 또는 "assistant"
    content = Column(String)                       # 대화 내용
    created_at = Column(DateTime, default=func.now())

# 복약 정보 테이블
class Medicine(Base):
    __tablename__ = "medicines"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)        # 약 이름
    dose = Column(String)        # 용량
    alarm_times = Column(String) # 알림 시간 (예: "08:30,13:00,19:00")
    start_date = Column(String)
    end_date = Column(String)

# 일정 테이블
class Schedule(Base):
    __tablename__ = "schedules"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)                         # 일정 제목
    datetime = Column(String)                      # 일정 시간
    memo = Column(String, nullable=True)
    is_completed = Column(Boolean, default=False)

# 위급 알림 테이블
class Alert(Base):
    __tablename__ = "alerts"

    id = Column(Integer, primary_key=True, index=True)
    type = Column(String)                          # 알림 종류
    message = Column(String)                       # 알림 내용
    is_resolved = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())