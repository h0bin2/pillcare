# flutter-back/create_tables.py

from db.database import DATABASE_URL, metadata # DB URL과 metadata 가져오기
from db.models import users # users 테이블 정의 가져오기 (다른 모델도 있다면 추가)
from sqlalchemy import create_engine

def create_db_tables():
    """models.py에 정의된 테이블들을 데이터베이스에 생성합니다."""
    print("테이블 생성 시도...")
    try:
        # SQLAlchemy 엔진 생성 (create_all은 동기 방식 사용)
        # databases 라이브러리의 비동기 접두사(+aiomysql) 제거
        sync_db_url = DATABASE_URL.replace("+aiomysql", "")
        engine = create_engine(sync_db_url)

        # metadata에 정의된 모든 테이블 생성
        metadata.create_all(bind=engine)
        print("테이블 생성 완료 (이미 존재하면 변경사항 없음).")

    except Exception as e:
        print(f"테이블 생성 중 오류 발생: {e}")
        print("DB 연결 정보 및 서버 상태를 확인하세요.")

if __name__ == "__main__":
    # 이 스크립트를 직접 실행할 때 테이블 생성 함수 호출
    # 주의: 이 스크립트를 실행하기 전에 DB 서버가 실행 중이고,
    # .env 파일에 올바른 DB 정보가 설정되어 있어야 합니다.
    create_db_tables() 