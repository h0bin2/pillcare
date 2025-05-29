import uvicorn
import os
from contextlib import asynccontextmanager # lifespan 사용 위해 임포트
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles # <--- StaticFiles 임포트
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, record, consultation, pill # 인증 라우터 임포트
from db.database import get_db # DB 연결 함수 임포트
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
    db = get_db()
    yield # 애플리케이션 실행

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

# --- 정적 파일 제공 설정 ---
# 현재 main.py 파일이 위치한 디렉토리 (flutter-back)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# flutter-back 디렉토리 내의 original_images 폴더
STATIC_FILES_DIR = os.path.join(BASE_DIR, "original_images")

# original_images 디렉토리가 없으면 생성 (선택 사항, 이미지를 저장하는 로직에서 폴더를 생성한다면 필요 없을 수 있음)
if not os.path.exists(STATIC_FILES_DIR):
    os.makedirs(STATIC_FILES_DIR)
    print(f"Created directory: {STATIC_FILES_DIR}") # 생성 확인 로그

# '/original_images' URL 경로로 STATIC_FILES_DIR 디렉토리의 파일을 제공
app.mount("/original_images", StaticFiles(directory=STATIC_FILES_DIR), name="original_images")
print(f"Serving static files from: {STATIC_FILES_DIR} at /original_images") # 설정 확인 로그


# --- 라우터 포함 ---
# /api/auth 접두사를 가진 auth 라우터 포함
app.include_router(auth.router)
app.include_router(record.router)
app.include_router(consultation.router)
app.include_router(pill.router)

# --- 기본 루트 엔드포인트 ---
@app.get("/")
def read_root():
    """서버 상태 확인용 기본 엔드포인트"""
    return {"message": "Welcome to Flutter FastAPI Auth Backend! DB Integrated & Lifespan. Static files configured."}

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
    uvicorn.run("main:app", host="0.0.0.0", port=5555, reload=True)