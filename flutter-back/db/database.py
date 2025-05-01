# flutter-back/db/database.py
import os
import databases
from dotenv import load_dotenv
from sqlalchemy import create_engine, MetaData # SQLAlchemy Core 사용 (선택적)

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

# databases 인스턴스 생성
database = databases.Database(DATABASE_URL)

# SQLAlchemy Core 메타데이터 (선택적, 테이블 정의 시 사용)
metadata = MetaData()

# SQLAlchemy 엔진 (선택적, 테이블 생성 등에 사용 가능)
# engine = create_engine(DATABASE_URL.replace("+aiomysql", "")) # databases는 비동기, engine은 동기용

async def connect_db():
    """데이터베이스 연결"""
    try:
        await database.connect()
        print(f"데이터베이스 연결 성공: {DB_HOST}:{DB_PORT}/{DB_NAME}")
    except Exception as e:
        print(f"데이터베이스 연결 오류: {e}")
        # 연결 실패 시 추가 처리 (예: 애플리케이션 종료)

async def disconnect_db():
    """데이터베이스 연결 해제"""
    try:
        await database.disconnect()
        print("데이터베이스 연결 해제됨.")
    except Exception as e:
        print(f"데이터베이스 연결 해제 오류: {e}")

# --- 환경 변수 미설정 경고 ---
if DB_USER == "your_db_user" or DB_PASSWORD == "your_db_password" or DB_NAME == "your_db_name":
    print("\n" + "*"*10 + " 경고 " + "*"*10)
    print("DB_USER, DB_PASSWORD, DB_NAME 환경 변수가 설정되지 않았습니다.")
    print("db/database.py 파일의 기본값을 사용합니다.")
    print("보안을 위해 환경 변수 설정을 강력히 권장합니다.")
    print("*"*25 + "\n") 