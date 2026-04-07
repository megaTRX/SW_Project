from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# 대화 로그
class ConversationCreate(BaseModel):
    session_id: str
    role: str
    content: str

class ConversationResponse(ConversationCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

# 복약 정보
class MedicineCreate(BaseModel):
    name: str
    dose: str
    alarm_times: str
    start_date: str
    end_date: str

class MedicineResponse(MedicineCreate):
    id: int
    taken: bool = False

    class Config:
        from_attributes = True

# 일정
class ScheduleCreate(BaseModel):
    title: str
    datetime: str
    memo: Optional[str] = None

class ScheduleResponse(ScheduleCreate):
    id: int
    is_completed: bool

    class Config:
        from_attributes = True

# 위급 알림
class AlertCreate(BaseModel):
    type: str
    message: str

class AlertResponse(AlertCreate):
    id: int
    is_resolved: bool
    created_at: datetime

    class Config:
        from_attributes = True

# 유저
class UserCreate(BaseModel):
    username: str
    password: str
    role: Optional[str] = "user"
    nickname: Optional[str] = None

class UserUpdate(BaseModel):
    role: Optional[str] = None
    nickname: Optional[str] = None
    is_active: Optional[bool] = None

class UserResponse(BaseModel):
    id: int
    username: str
    role: str
    nickname: Optional[str]
    social_provider: Optional[str]
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class LoginRequest(BaseModel):
    username: str
    password: str