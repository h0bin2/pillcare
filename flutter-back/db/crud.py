# flutter-back/db/crud.py
from .database import database # database 인스턴스 임포트
from .models import users, consultations, records, record_details # users 테이블 모델 임포트
from schemas.schemas import UserInfo, ConsultationHistory, Record # Pydantic 스키마 임포트 (반환 타입 명시용)
from fastapi import HTTPException

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

async def get_consultation_history_read(user_id: int):
    """상담 내역 조회"""
    try:
        consultation_history = await database.fetch_all(consultations.select().where(consultations.c.user_id == user_id))

        return consultation_history
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
async def get_consultation_history_by_id(consultation_id: int):
    """상담 내역 조회"""
    try:
        consultation = await database.fetch_one(consultations.select().where(consultations.c.id == consultation_id))
        return consultation
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def insert_consultation(consultation: ConsultationHistory):
    """상담 내역 추가"""
    try:
        consultation = consultations.insert().values(
            user_id=consultation.user_id,
            pharmacy_id=consultation.pharmacy_id,
            created_at=consultation.created_at,
            updated_at=consultation.updated_at,
            status=consultation.status,
            history=consultation.history
        )
        await database.execute(consultation)
        return True
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
async def get_consultation_history_by_id(consultation_id: int):
    """상담 내역 조회"""
    try:
        consultation = await database.fetch_one(consultations.select().where(consultations.c.id == consultation_id))
        return consultation
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def update_consultation(consultation_id: int, consultation: ConsultationHistory):
    """상담 내역 수정"""
    try:
        consultation = consultations.update().where(consultations.c.id == consultation_id).values(
            user_id=consultation.user_id,
            pharmacy_id=consultation.pharmacy_id,
            created_at=consultation.created_at,
            updated_at=consultation.updated_at,
            status=consultation.status,
            history=consultation.history
        )
        await database.execute(consultation)
        return True
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def delete_consultation(consultation_id: int):
    """상담 내역 삭제"""
    try:
        await database.execute(consultations.delete().where(consultations.c.id == consultation_id))
        return True
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    

async def insert_record(record:Record, user_id: int, original_image_path: str, class_name: list[str], boxes: list[list[float]]):
    """레코드 추가"""
    try:
        record = records.insert().values(
            user_id=user_id,
            original_image_path=original_image_path
            )
        await database.execute(record)
        return True
    except Exception as e:
        
        raise HTTPException(status_code=500, detail=str(e))

async def insert_record_detail(record_id: int, class_name: list[str], boxes: list[list[float]]):
    """레코드 상세 추가"""
    try:
        for i in range(len(class_name)):
            record_detail = record_details.insert().values(
                record_id=record_id,
                drug_code=class_name[i],
                pill_count=1
            )
            await database.execute(record_detail)
        return True
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
async def request_consultation(consultation: ConsultationHistory):
    """상담 요청"""
    try:
        await database.execute(consultations.insert().values(consultation))
        return True
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))