# flutter-back/db/models.py
import sqlalchemy
from .database import metadata # database.py 에서 정의한 metadata 가져오기

# 사용자 테이블 정의
users = sqlalchemy.Table(
    "users",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True), # 자동 증가 ID (선택적)
    sqlalchemy.Column("kakao_id", sqlalchemy.String(length=255), unique=True, index=True, nullable=False), # 카카오 고유 ID
    sqlalchemy.Column("nickname", sqlalchemy.String(length=255), nullable=True), # 카카오 닉네임
    sqlalchemy.Column("profile_image_url", sqlalchemy.String(length=2048), nullable=True), # 프로필 이미지 URL (길이 조절 필요)
    sqlalchemy.Column("created_at", sqlalchemy.DateTime, server_default=sqlalchemy.func.now()),
    sqlalchemy.Column("updated_at", sqlalchemy.DateTime, server_default=sqlalchemy.func.now(), onupdate=sqlalchemy.func.now()),
    # 필요에 따라 다른 필드 추가 (예: email, is_active 등)
)

# 참고: 위 테이블을 실제 DB에 생성하려면 Alembic 같은 마이그레이션 도구를 사용하거나,
# 별도의 스크립트에서 metadata.create_all(engine)을 실행해야 합니다.
# 예시:
# from .database import engine
# metadata.create_all(bind=engine) 