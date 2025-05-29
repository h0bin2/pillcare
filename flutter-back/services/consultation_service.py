from db.models import consultations, pharmacies
from sqlalchemy.orm import Session
from datetime import datetime
from fastapi import HTTPException
from schemas.schemas import ConsultationHistory
from db.crud import get_consultation_history_read, get_consultation_history_by_id, insert_consultation, update_consultation, delete_consultation, request_consultation

def _get_consultation_history(user_id: int, db: Session):
    """상담 내역 조회"""
    try:
        consultation_history = get_consultation_history_read(user_id, db)
        return consultation_history
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
async def _get_consultation_history_by_id(consultation_id: int, db: Session):
    """상담 내역 조회"""
    try:
        consultation = await get_consultation_history_by_id(consultation_id, db)
        return consultation
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
def get_or_create_pharmacy(name: str, address: str, phone: str = None, db: Session = None):
    print(f"get_or_create_pharmacy: name={name}, address={address}, phone={phone}")
    if not name or not address:
        print("name 또는 address가 None/빈 문자열입니다!")
        raise HTTPException(status_code=400, detail="약국 이름과 주소는 필수입니다.")
    try:
        pharmacy = db.execute(
            pharmacies.select().where(
                (pharmacies.c.name == name) & (pharmacies.c.address == address)
            )
        ).fetchone()
        print(f"pharmacy select result: {pharmacy}")
    except Exception as e:
        print(f"DB 조회 에러: {e}")
        raise HTTPException(status_code=500, detail=f"DB 조회 에러: {e}")
    
    if pharmacy:
        print(f"이미 존재하는 약국, id={pharmacy.id}")
        return pharmacy.id
    
    print("새 약국 insert 시도")
    ins = pharmacies.insert().values(
        name=name,
        address=address,
        phone=phone
    )
    try:
        result = db.execute(ins)
        db.commit()
        new_id = result.inserted_primary_key[0]
        print(f"inserted pharmacy, new_id={new_id}")
        if new_id is None:
            print("insert 후 id를 못 받아옴!")
            raise HTTPException(status_code=500, detail="약국 insert 후 id를 가져오지 못했습니다.")
        return new_id
    except Exception as e:
        print(f"약국 insert 에러: {e}")
        raise HTTPException(status_code=500, detail=f"약국 insert 에러: {e}")

async def _insert_consultation(consultation: ConsultationHistory, db: Session):
    """상담 내역 추가 (약국 없으면 먼저 insert)"""
    try:
        # 약국 id 확보 (이름+주소로 중복 체크, 없으면 insert)
        pharmacy_id = get_or_create_pharmacy(
            name=consultation.pharmacy_name,
            address=consultation.pharmacy_address,
            phone=consultation.pharmacy_phone,
            db=db
        )
        print(f"pharmacy_id: {pharmacy_id}")
        consultation.pharmacy_id = pharmacy_id
        insert_consultation(consultation, db)
        return True
    except Exception as e:
        return False
    
async def _update_consultation(consultation_id: int, consultation: ConsultationHistory, db: Session):
    """상담 내역 수정"""
    try:
        if consultation.status in ("receipt", "complete"):
            await update_consultation(consultation_id, consultation, db)
            return True
        else:
            return False
    except Exception as e:
        return False
    

async def _delete_consultation(consultation_id: int, db: Session):
    """상담 내역 삭제"""
    try:
        await delete_consultation(consultation_id, db)
        return True
    except Exception as e:
        return False
    
async def _request_consultation(consultation: ConsultationHistory, db: Session):
    """상담 요청"""
    try:
        await request_consultation(consultation, db)
        return True
    except Exception as e:
        return False