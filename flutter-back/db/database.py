# flutter-back/db/database.py
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from core.config import settings
from db.metadata import metadata

load_dotenv()

# --- 데이터베이스 연결 정보 ---
# !!! 중요: 실제 환경에서는 환경 변수 사용 필수 !!!
DB_USER = os.getenv("DB_USER", "your_db_user") # <- 실제 DB 사용자 이름으로 변경 또는 환경 변수 설정
DB_PASSWORD = os.getenv("DB_PASSWORD", "your_db_password") # <- 실제 DB 비밀번호로 변경 또는 환경 변수 설정
DB_HOST = os.getenv("DB_HOST", "localhost") # 사용자 제공 IP
DB_PORT = os.getenv("DB_PORT", "3306") # MySQL 기본 포트
DB_NAME = os.getenv("DB_NAME", "pillcare") # <- 실제 DB 이름으로 변경 또는 환경 변수 설정

# databases 라이브러리 연결 URL 생성
# 형식: "mysql+aiomysql://<user>:<password>@<host>:<port>/<database_name>"
DATABASE_URL = f"mysql+aiomysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL
engine = create_engine(SQLALCHEMY_DATABASE_URL, pool_pre_ping=True, pool_recycle=3600)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- 환경 변수 미설정 경고 ---
if DB_USER == "your_db_user" or DB_PASSWORD == "your_db_password" or DB_NAME == "your_db_name":
    print("\n" + "*"*10 + " 경고 " + "*"*10)
    print("DB_USER, DB_PASSWORD, DB_NAME 환경 변수가 설정되지 않았습니다.")
    print("db/database.py 파일의 기본값을 사용합니다.")
    print("보안을 위해 환경 변수 설정을 강력히 권장합니다.")
    print("*"*25 + "\n")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()