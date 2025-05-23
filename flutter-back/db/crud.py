# flutter-back/db/crud.py
# from .database import database # database 인스턴스 임포트
from .models import users, consultations, records, record_details, pharmacies, pills # users 테이블 모델 임포트
from schemas.schemas import UserInfo, ConsultationHistory, Record # Pydantic 스키마 임포트 (반환 타입 명시용)
from fastapi import HTTPException
import traceback # 상세 오류 출력을 위해 추가
from sqlalchemy import select # select 임포트 추가
from datetime import timezone # 이미 있다면 생략 가능
import pytz # 없다면 추가 (pip install pytz 필요)
from sqlalchemy.orm import Session
from db.database import get_db
from fastapi import Depends

def get_user_by_kakao_id(kakao_id: str, db: Session) -> UserInfo | None:
    """카카오 ID로 사용자 조회"""
    query = users.select().where(users.c.kakao_id == kakao_id)
    result = db.execute(query).mappings().fetchone()
    if result:
        return UserInfo(kakao_id=result["kakao_id"], nickname=result["nickname"], id=result["id"], kakao_profile_image_url=result["profile_image_url"])
    return None

def create_user(kakao_id: str, nickname: str | None, profile_image_url: str | None, db: Session) -> UserInfo:
    """새로운 사용자 생성"""
    query = users.insert().values(
        kakao_id=kakao_id,
        nickname=nickname,
        profile_image_url=profile_image_url
    )
    db.execute(query)
    db.commit()
    return UserInfo(kakao_id=kakao_id, nickname=nickname)

def get_or_create_user(kakao_id: str, nickname: str | None, profile_image_url: str | None, db: Session) -> UserInfo:
    """사용자를 조회하고 없으면 생성"""
    user = get_user_by_kakao_id(kakao_id, db)
    if user:
        print(f"기존 사용자 반환: {kakao_id}")
        return user
    else:
        print(f"새 사용자 생성: {kakao_id}")
        new_user = create_user(kakao_id, nickname, profile_image_url, db)
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

def get_consultation_history_read(user_id: int, db: Session):
    """상담 내역 조회"""
    try:
        consultation_history = db.execute(
            consultations.join(
                pharmacies,
                consultations.c.pharmacy_id == pharmacies.c.id
            ).select().where(consultations.c.user_id == user_id).order_by(consultations.c.created_at.desc()).limit(2)
        ).mappings().fetchall()
        # 변환: name → pharmacy_name, address → pharmacy_address, phone → pharmacy_phone
        result = []
        for row in consultation_history:
            row = dict(row)
            row['pharmacy_name'] = row.pop('name', None)
            row['pharmacy_address'] = row.pop('address', None)
            row['pharmacy_phone'] = row.pop('phone', None)
            result.append(row)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_consultation_history_by_id(consultation_id: int, db: Session):
    """상담 내역 조회"""
    try:
        consultation = db.execute(consultations.select().where(consultations.c.id == consultation_id)).mappings().fetchone()
        return consultation
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def insert_consultation(consultation: ConsultationHistory, db: Session):
    """상담 내역 추가"""
    try:
        print(f"insert_consultation: id={consultation.id} user_id={consultation.user_id} pharmacy_id={consultation.pharmacy_id} created_at={consultation.created_at} updated_at={consultation.updated_at} status={consultation.status} history={consultation.history}")
        consultation_values = consultations.insert().values(
            user_id=consultation.user_id,
            pharmacy_id=consultation.pharmacy_id,
            created_at=consultation.created_at,
            updated_at=consultation.updated_at,
            status=consultation.status,
            history=consultation.history
        )
        db.execute(consultation_values)
        db.commit()
        return True
    except Exception as e:
        print(f"insert_consultation error: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

def update_consultation(consultation_id: int, consultation: ConsultationHistory, db: Session):
    """상담 내역 수정"""
    try:
        consultation_update_values = consultations.update().where(consultations.c.id == consultation_id).values(
            user_id=consultation.user_id,
            pharmacy_id=consultation.pharmacy_id,
            created_at=consultation.created_at,
            updated_at=consultation.updated_at,
            status=consultation.status,
            history=consultation.history
        )
        db.execute(consultation_update_values)
        db.commit()
        return True
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

def delete_consultation(consultation_id: int, db: Session):
    """상담 내역 삭제"""
    try:
        db.execute(consultations.delete().where(consultations.c.id == consultation_id))
        db.commit()
        return True
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

async def insert_record(user_id: int, original_image_path: str, db: Session):
    """레코드 추가"""
    try:
        query = records.insert().values(
            user_id=user_id,
            original_image_path=original_image_path
        )
        last_record_id = db.execute(query)
        if last_record_id:
            return last_record_id
        else:
            raise Exception("Failed to get last record id after insert. The database may not be returning the ID, or the insert failed silently.")
    except Exception as e:
        print(f"Error inserting record: {e}")
        traceback.print_exc() 
        raise HTTPException(status_code=500, detail=f"DB Error inserting record: {str(e)}")

def insert_record_detail(record_id: int, class_name_list: list[str], boxes_list: list[list[float]], db: Session):
    """레코드 상세 추가 (바운딩 박스 정보 포함)"""
    try:
        if len(class_name_list) != len(boxes_list):
            raise ValueError("The number of class names and boxes do not match.")

        for i in range(len(class_name_list)):
            drug_name = class_name_list[i]
            box = boxes_list[i] 

            if len(box) != 4:
                print(f"Warning: Invalid bounding box format for '{drug_name}'. Box: {box}. Skipping.")
                continue

            pill_query = pills.select().where(pills.c.drug_name == drug_name)
            pill_result = db.execute(pill_query).fetchone()

            if pill_result:
                pill_id_from_db = pill_result["id"]
                detail_query = record_details.insert().values(
                    record_id=record_id,
                    pill_id=pill_id_from_db,
                    pill_count=1, 
                    box_x1=box[0],
                    box_y1=box[1],
                    box_x2=box[2],
                    box_y2=box[3]
                )
                db.execute(detail_query)
                db.commit()
            else:
                print(f"Warning: Pill information for '{drug_name}' not found in pills table. Skipping record_detail insertion for this pill.")
        return True
    except ValueError as ve: 
        print(f"ValueError in insert_record_detail: {ve}")
        traceback.print_exc()
        db.rollback()
        raise HTTPException(status_code=400, detail=str(ve)) 
    except Exception as e:
        print(f"Error inserting record detail: {e}")
        traceback.print_exc()
        db.rollback()
        raise HTTPException(status_code=500, detail=f"DB Error inserting record detail: {str(e)}")

def get_pill_info(drug_name: str, db: Session):
    """약 정보 조회"""
    try:
        pill_info = db.execute(pills.select().where(pills.c.drug_name == drug_name)).mappings().fetchone()
        return pill_info
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def request_consultation(consultation: ConsultationHistory, db: Session):
    """상담 요청 - 값 매핑 수정"""
    try:
        query = consultations.insert().values(
            user_id=consultation.user_id,
            pharmacy_id=consultation.pharmacy_id,
            created_at=consultation.created_at, # 스키마에 따라 자동 생성될 수도 있음
            updated_at=consultation.updated_at, # 스키마에 따라 자동 생성될 수도 있음
            status=consultation.status,
            history=consultation.history
        )
        db.execute(query)
        db.commit()
        return True
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"DB Error requesting consultation: {str(e)}")

# 레코드 삭제를 위한 CRUD 함수들
def delete_record_details_by_record_id(record_id: int, db: Session) -> bool:
    """특정 레코드 ID에 해당하는 모든 레코드 상세 정보 삭제"""
    try:
        query = record_details.delete().where(record_details.c.record_id == record_id)
        db.execute(query)
        db.commit()
        return True 
    except Exception as e:
        print(f"Error deleting record details for record_id {record_id}: {e}")
        traceback.print_exc()
        db.rollback()
        return False

def delete_record_by_id(record_id: int, db: Session) -> bool:
    """특정 ID의 레코드 삭제"""
    try:
        query = records.delete().where(records.c.id == record_id)
        result = db.execute(query)
        db.commit()
        return result.rowcount > 0 if result is not None else True
    except Exception as e:
        print(f"Error deleting record with id {record_id}: {e}")
        traceback.print_exc()
        db.rollback()
        return False

# (선택적) 사용자 ID와 레코드 ID로 레코드를 조회하는 함수 (삭제 전 권한 확인용)
def get_record_by_id_and_user_id(db: Session, record_id: int, user_id: int):
    query = records.select().where(records.c.id == record_id).where(records.c.user_id == user_id)
    return db.execute(query).mappings().fetchone()

def get_records_with_details_by_user_id(user_id: int, db: Session) -> list:
    """사용자 ID로 모든 레코드와 관련 약물 상세 정보 조회 (created_at을 KST로 변환)"""
    records_query = records.select().where(records.c.user_id == user_id).order_by(records.c.created_at.desc())
    user_records = db.execute(records_query).mappings().fetchall()

    result_records = []
    kst = pytz.timezone('Asia/Seoul') # KST 시간대 객체

    for record_row in user_records:
        details_query = select(
            record_details.c.pill_id, 
            record_details.c.pill_count, 
            pills.c.drug_name.label("pill_name"),
            pills.c.dosage,
            pills.c.effect
        ).select_from(
            record_details.join(pills, record_details.c.pill_id == pills.c.id)
        ).where(record_details.c.record_id == record_row['id'])
        record_details_list = db.execute(details_query).mappings().fetchall()
        record_data = dict(record_row)
        created_at_from_db = record_data.get('created_at')
        if created_at_from_db:
            if created_at_from_db.tzinfo is None or created_at_from_db.tzinfo.utcoffset(created_at_from_db) is None:
                created_at_utc_aware = pytz.utc.localize(created_at_from_db)
            else:
                created_at_utc_aware = created_at_from_db
            created_at_kst = created_at_utc_aware.astimezone(kst)
            record_data['created_at'] = created_at_kst.isoformat()
        else:
            record_data['created_at'] = None 
            print(f"Warning: record_id {record_data.get('id')} has no created_at value.")
        record_data['details'] = [dict(detail) for detail in record_details_list] 
        result_records.append(record_data)
    return result_records

def delete_pill_by_id(record_id: int, pill_id: int, db: Session) -> bool:
    """특정 ID의 약품 삭제"""
    try:
        query = record_details.delete().where(record_details.c.record_id == record_id).where(record_details.c.pill_id == pill_id)
        result = db.execute(query)
        db.commit()
        return result.rowcount > 0 if result is not None else True
    except Exception as e:
        print(f"Error deleting pill with id {pill_id}: {e}")
        traceback.print_exc()
        db.rollback()
        return False
