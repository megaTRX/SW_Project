from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
import httpx

router = APIRouter()

SECRET_KEY = "노인케어챗봇시크릿키2026"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")

# pwd_context 아래에 있어야 해요!
ADMIN_USERS = {
    "admin": {
        "username": "admin",
        "hashed_password": pwd_context.hash("1234"),
        "role": "admin"
    }
}

KAKAO_CLIENT_ID = "your_kakao_client_id"
GOOGLE_CLIENT_ID = "your_google_client_id"
GOOGLE_CLIENT_SECRET = "your_google_client_secret"

class Token(BaseModel):
    access_token: str
    token_type: str

class SocialLoginRequest(BaseModel):
    access_token: str

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password[:72], hashed_password)

@router.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = ADMIN_USERS.get(form_data.username)
    if not user or not verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(status_code=401, detail="아이디 또는 비밀번호가 올바르지 않습니다")
    access_token = create_access_token({"sub": user["username"], "role": user["role"]})
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/kakao", response_model=Token)
async def kakao_login(request: SocialLoginRequest):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://kapi.kakao.com/v2/user/me",
            headers={"Authorization": f"Bearer {request.access_token}"}
        )
    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="카카오 인증 실패")
    kakao_user = response.json()
    user_id = str(kakao_user["id"])
    nickname = kakao_user.get("properties", {}).get("nickname", "사용자")
    access_token = create_access_token({"sub": f"kakao_{user_id}", "nickname": nickname, "role": "user"})
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/google", response_model=Token)
async def google_login(request: SocialLoginRequest):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://www.googleapis.com/oauth2/v3/userinfo",
            headers={"Authorization": f"Bearer {request.access_token}"}
        )
    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="구글 인증 실패")
    google_user = response.json()
    user_id = google_user["sub"]
    nickname = google_user.get("name", "사용자")
    access_token = create_access_token({"sub": f"google_{user_id}", "nickname": nickname, "role": "user"})
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me")
async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="토큰이 유효하지 않습니다")
        return {"username": username, "role": payload.get("role")}
    except JWTError:
        raise HTTPException(status_code=401, detail="토큰이 유효하지 않습니다")