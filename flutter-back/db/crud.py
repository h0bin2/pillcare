# flutter-back/db/crud.py
from .database import database # database 인스턴스 임포트
from .models import users # users 테이블 모델 임포트
from schemas.schemas import UserInfo # Pydantic 스키마 임포트 (반환 타입 명시용)

async def get_user_by_kakao_id(kakao_id: str) -> UserInfo | None:
    """카카오 ID로 사용자 조회"""
    query = users.select().where(users.c.kakao_id == kakao_id)
    result = await database.fetch_one(query)
    if result:
        # DB 결과를 UserInfo 스키마로 변환 (필요한 필드만 매핑)
        return UserInfo(kakao_id=result["kakao_id"], nickname=result["nickname"])
    return None

async def create_user(kakao_id: str, nickname: str | None, profile_image_url: str | None) -> UserInfo:
    """새로운 사용자 생성"""
    query = users.insert().values(
        kakao_id=kakao_id,
        nickname=nickname,
        profile_image_url=profile_image_url
        # created_at, updated_at은 DB 기본값 사용
    )
    # 생성된 레코드의 ID가 필요하면 last_record_id 사용 (여기서는 불필요)
    last_record_id = await database.execute(query)
    # 생성된 사용자 정보를 UserInfo 스키마로 반환
    # 주의: last_record_id는 Auto Increment ID, 여기서는 kakao_id 기반으로 반환
    return UserInfo(kakao_id=kakao_id, nickname=nickname)

async def get_or_create_user(kakao_id: str, nickname: str | None, profile_image_url: str | None) -> UserInfo:
    """사용자를 조회하고 없으면 생성"""
    user = await get_user_by_kakao_id(kakao_id)
    if user:
        # (선택적) 사용자 정보 업데이트 로직 추가 가능
        # if user.nickname != nickname or ...:
        #     await update_user(...)
        print(f"기존 사용자 반환: {kakao_id}")
        return user
    else:
        print(f"새 사용자 생성: {kakao_id}")
        new_user = await create_user(kakao_id, nickname, profile_image_url)
        return new_user

# (선택적) 사용자 정보 업데이트 함수
async def update_user_profile(kakao_id: str, nickname: str | None, profile_image_url: str | None) -> bool:
    """사용자 프로필 정보 업데이트"""
    query = (
        users.update()
        .where(users.c.kakao_id == kakao_id)
        .values(nickname=nickname, profile_image_url=profile_image_url)
        # updated_at은 자동으로 갱신됨 (onupdate 설정)
    )
    result = await database.execute(query)
    return result > 0 # 업데이트된 행이 있으면 True 반환 