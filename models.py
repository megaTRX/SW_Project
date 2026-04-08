from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from database import Base

# 대화 로그 테이블
class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, index=True)
    role = Column(String)
    content = Column(String)
    type = Column(String, default="생활정보")
    created_at = Column(DateTime, default=func.now())

# 복약 정보 테이블
class Medicine(Base):
    __tablename__ = "medicines"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    dose = Column(String)
    alarm_times = Column(String)
    start_date = Column(String)
    end_date = Column(String)
    taken = Column(Boolean, default=False)

# 일정 테이블
class Schedule(Base):
    __tablename__ = "schedules"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    datetime = Column(String)
    memo = Column(String, nullable=True)
    is_completed = Column(Boolean, default=False)

# 위급 알림 테이블
class Alert(Base):
    __tablename__ = "alerts"

    id = Column(Integer, primary_key=True, index=True)
    type = Column(String)
    message = Column(String)
    is_resolved = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())

# 유저 테이블
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String, nullable=True)
    role = Column(String, default="user")
    social_provider = Column(String, nullable=True)
    social_id = Column(String, nullable=True)
    nickname = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())