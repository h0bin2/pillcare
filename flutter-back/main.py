import uvicorn
import os
from contextlib import asynccontextmanager # lifespan 사용 위해 임포트
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth # 인증 라우터 임포트
from db.database import connect_db, disconnect_db # DB 연결 함수 임포트
from dotenv import load_dotenv

# .env 파일 로드 (선택적)
load_dotenv()

# 환경 변수 로드 (JWT 서비스에서 사용되지만, 여기서 로드해도 무방)
SECRET_KEY = os.getenv("SECRET_KEY", "default_secret_key_please_change")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))

# --- Lifespan 이벤트 핸들러 --- 
@asynccontextmanager
async def lifespan(app: FastAPI):
    """애플리케이션 시작 시 DB 연결, 종료 시 연결 해제"""
    await connect_db()
    yield # 애플리케이션 실행
    await disconnect_db()

# FastAPI 앱 인스턴스 생성 (lifespan 인자 추가)
app = FastAPI(title="Flutter FastAPI Auth Example with DB", lifespan=lifespan)

# --- CORS 설정 ---
origins = [
    "http://localhost",
    "http://localhost:8080", # Flutter 웹 개발 포트 등 필요에 따라 추가
    "*" # 개발 편의상 모든 출처 허용 (배포 시 실제 출처로 변경 권장)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"], # 모든 HTTP 메소드 허용
    allow_headers=["*"], # 모든 HTTP 헤더 허용
)

# --- 라우터 포함 ---
# /api/auth 접두사를 가진 auth 라우터 포함
app.include_router(auth.router)

# --- 기본 루트 엔드포인트 ---
@app.get("/")
def read_root():
    """서버 상태 확인용 기본 엔드포인트"""
    return {"message": "Welcome to Flutter FastAPI Auth Backend! DB Integrated & Lifespan."}

# 서버 실행 (개발용)
if __name__ == "__main__":
    # SECRET_KEY 설정 여부 확인 및 경고 (선택적)
    if SECRET_KEY == "default_secret_key_please_change":
        print("\n*** 경고: SECRET_KEY 환경 변수가 설정되지 않았습니다. 기본값을 사용합니다. 보안을 위해 반드시 설정하세요. ***\n")
    else:
         print(f"Starting server with SECRET_KEY loaded.")

    print(f"Using ALGORITHM: {ALGORITHM}")
    print(f"Token expires in: {ACCESS_TOKEN_EXPIRE_MINUTES} minutes")
    # DB 연결 정보는 connect_db 함수에서 출력
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)