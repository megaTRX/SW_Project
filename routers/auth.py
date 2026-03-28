from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

# 졸작용 고정 계정 (나중에 DB 연동으로 확장 가능)
ADMIN_ID = "admin"
ADMIN_PW = "1234"

class LoginRequest(BaseModel):
    username: str
    password: str

class LoginResponse(BaseModel):
    success: bool
    message: str
    role: str = ""

@router.post("/login", response_model=LoginResponse)
async def login(req: LoginRequest):
    if req.username == ADMIN_ID and req.password == ADMIN_PW:
        return LoginResponse(success=True, message="로그인 성공", role="admin")
    raise HTTPException(status_code=401, detail="아이디 또는 비밀번호가 올바르지 않습니다")
