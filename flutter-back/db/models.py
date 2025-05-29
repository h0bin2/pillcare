# flutter-back/db/models.py
import sqlalchemy
from db.metadata import metadata # metadata를 별도 파일에서 import

# 사용자 테이블 정의
users = sqlalchemy.Table(
    "users",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True, autoincrement=True), # 자동 증가 ID (선택적)
    sqlalchemy.Column("kakao_id", sqlalchemy.String(length=255), unique=True, index=True, nullable=False), # 카카오 고유 ID
    sqlalchemy.Column("nickname", sqlalchemy.String(length=255), nullable=True), # 카카오 닉네임
    sqlalchemy.Column("profile_image_url", sqlalchemy.String(length=2048), nullable=True), # 프로필 이미지 URL (길이 조절 필요)
    sqlalchemy.Column("created_at", sqlalchemy.DateTime, server_default=sqlalchemy.func.now()),
    sqlalchemy.Column("updated_at", sqlalchemy.DateTime, server_default=sqlalchemy.func.now(), onupdate=sqlalchemy.func.now()),
    # 필요에 따라 다른 필드 추가 (예: email, is_active 등)
)

# 상담 내역 테이블 정의
consultations = sqlalchemy.Table(
    "consultations",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True, autoincrement=True),
    sqlalchemy.Column("user_id", sqlalchemy.Integer, nullable=False),
    sqlalchemy.Column("pharmacy_id", sqlalchemy.Integer, nullable=False),
    sqlalchemy.Column("created_at", sqlalchemy.DateTime, server_default=sqlalchemy.func.now()),
    sqlalchemy.Column("updated_at", sqlalchemy.DateTime, server_default=sqlalchemy.func.now(), onupdate=sqlalchemy.func.now()),
    sqlalchemy.Column("status", sqlalchemy.String(length=255), nullable=False),
    sqlalchemy.Column("history", sqlalchemy.String(length=2048), nullable=False),

    sqlalchemy.ForeignKeyConstraint(
        ["user_id"],
        ["users.id"],
        ondelete="CASCADE"
    ),

    sqlalchemy.ForeignKeyConstraint(
        ["pharmacy_id"],
        ["pharmacies.id"],
        ondelete="CASCADE"
    )
)

pharmacies = sqlalchemy.Table(
    "pharmacies",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True, autoincrement=True),
    sqlalchemy.Column("name", sqlalchemy.String(length=255), nullable=False),
    sqlalchemy.Column("address", sqlalchemy.String(length=2048), nullable=False),
    sqlalchemy.Column("phone", sqlalchemy.String(length=255), nullable=True),
)

records = sqlalchemy.Table(
    "records",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True, autoincrement=True),
    sqlalchemy.Column("user_id", sqlalchemy.Integer, nullable=False),
    sqlalchemy.Column("created_at", sqlalchemy.DateTime, server_default=sqlalchemy.func.now()),
    sqlalchemy.Column("original_image_path", sqlalchemy.String(length=2048), nullable=False),
    sqlalchemy.ForeignKeyConstraint(
        ["user_id"],
        ["users.id"],
        ondelete="CASCADE"
    ),
)

record_details = sqlalchemy.Table(
    "record_details",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True, autoincrement=True),
    sqlalchemy.Column("record_id", sqlalchemy.Integer, nullable=False),
    sqlalchemy.Column("pill_id", sqlalchemy.Integer, nullable=False),
    sqlalchemy.Column("pill_count", sqlalchemy.Integer, nullable=False),
    sqlalchemy.Column("box_x1", sqlalchemy.Float, nullable=False),
    sqlalchemy.Column("box_y1", sqlalchemy.Float, nullable=False),
    sqlalchemy.Column("box_x2", sqlalchemy.Float, nullable=False),
    sqlalchemy.Column("box_y2", sqlalchemy.Float, nullable=False),
    sqlalchemy.ForeignKeyConstraint(
        ["record_id"],
        ["records.id"],
        ondelete="CASCADE"
    ),
    sqlalchemy.ForeignKeyConstraint(
        ["pill_id"],
        ["pills.id"],
        ondelete="CASCADE"
    ),
    
)

pills = sqlalchemy.Table(
    "pills",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True, autoincrement=True),
    sqlalchemy.Column("drug_code", sqlalchemy.String(length=255), nullable=False),
    sqlalchemy.Column("drug_name", sqlalchemy.String(length=255), nullable=False),
    sqlalchemy.Column("dosage", sqlalchemy.String(length=255), nullable=False),
    sqlalchemy.Column("effect", sqlalchemy.String(length=255), nullable=False),
    sqlalchemy.Column("caution", sqlalchemy.String(length=255), nullable=False),
)

# 참고: 위 테이블을 실제 DB에 생성하려면 Alembic 같은 마이그레이션 도구를 사용하거나,
# 별도의 스크립트에서 metadata.create_all(engine)을 실행해야 합니다.
# 예시:
# from .database import engine
# metadata.create_all(bind=engine) 