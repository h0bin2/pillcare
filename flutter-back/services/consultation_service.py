from db.models import consultations
from sqlalchemy.orm import Session
from datetime import datetime
from fastapi import HTTPException, Depends
from schemas.schemas import ConsultationHistory
from db.crud import get_consultation_history_read, get_consultation_history_by_id, insert_consultation, update_consultation, delete_consultation, request_consultation

async def _get_consultation_history(user_id: int):
    """상담 내역 조회"""
    try:
        consultation_history = await get_consultation_history_read(user_id)
        return consultation_history
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
async def _get_consultation_history_by_id(consultation_id: int):
    """상담 내역 조회"""
    try:
        consultation = await get_consultation_history_by_id(consultation_id)
        return consultation
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
async def _insert_consultation(consultation: ConsultationHistory):
    """상담 내역 추가"""
    try:
        if consultation.status == "progress":
            await insert_consultation(consultation)
            return True
        else:
            return False
    except Exception as e:
        return False
    
async def _update_consultation(consultation_id: int, consultation: ConsultationHistory):
    """상담 내역 수정"""
    try:
        if consultation.status in ("receipt", "complete"):
            await update_consultation(consultation_id, consultation)
            return True
        else:
            return False
    except Exception as e:
        return False
    

async def _delete_consultation(consultation_id: int):
    """상담 내역 삭제"""
    try:
        await delete_consultation(consultation_id)
        return True
    except Exception as e:
        return False
    
async def _request_consultation(consultation: ConsultationHistory):
    """상담 요청"""
    try:
        await request_consultation(consultation)
        return True
    except Exception as e:
        return False