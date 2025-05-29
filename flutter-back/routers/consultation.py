from fastapi import APIRouter, Depends, HTTPException, status
from services.consultation_service import (
    _get_consultation_history as get_consultation_history_service,
    _get_consultation_history_by_id as get_consultation_history_by_id_service,
    _insert_consultation as insert_consultation_service,
    _update_consultation as update_consultation_service,
    _delete_consultation as delete_consultation_service,
    _request_consultation as request_consultation_service
)
from schemas.schemas import ConsultationHistory
from fastapi.responses import JSONResponse
from typing import List
from sqlalchemy.orm import Session
from db.database import get_db

router = APIRouter(prefix="/api/consultation", tags=["consultation"])

@router.get('/history', response_model=List[ConsultationHistory])
async def get_consultation_history_api(user_id: int, db: Session = Depends(get_db)):
    """상담 내역 조회"""
    try:
        consultations = get_consultation_history_service(user_id, db=db)
        return consultations
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"Error in get_consultation_history_api: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal server error while fetching consultation history.")
    
@router.get('/history_datail/{consultation_id}', response_model=ConsultationHistory)
async def get_consultation_history_by_id_api(consultation_id: int, db: Session = Depends(get_db)):
    """상담 내역 조회"""
    try:
        consultation = await get_consultation_history_by_id_service(consultation_id, db=db)
        if consultation is None:
            raise HTTPException(status_code=404, detail="Consultation not found")
        return consultation
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"Error in get_consultation_history_by_id_api: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal server error while fetching consultation detail.")
    
@router.post('/insert')
async def insert_consultation(consultation: ConsultationHistory, db: Session = Depends(get_db)):
    """상담 내역 추가"""
    try:
        print(f"consultation: {consultation}")
        consultation_response = await insert_consultation_service(consultation, db=db)
        print(f"consultation_response: {consultation_response}")
        if consultation_response:
            response = JSONResponse(status_code=200, content=consultation_response)
            return response
        else:
            raise HTTPException(status_code=404, detail="Consultation not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@router.put('/update/{consultation_id}')
async def update_consultation(consultation_id: int, consultation: ConsultationHistory, db: Session = Depends(get_db)):
    """상담 내역 수정"""
    try:
        consultation = await update_consultation_service(consultation_id, consultation, db=db)
        if consultation:
            response = JSONResponse(status_code=200, content=consultation)
            return response
        else:
            raise HTTPException(status_code=404, detail="Consultation not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@router.delete('/delete/{consultation_id}')
async def delete_consultation(consultation_id: int, db: Session = Depends(get_db)):
    """상담 내역 삭제"""
    try:
        consultation = await delete_consultation_service(consultation_id, db=db)
        if consultation:
            response = JSONResponse(status_code=200, content=consultation)
            return response
        else:
            raise HTTPException(status_code=404, detail="Consultation not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    

@router.post('/request')
async def request_consultation(consultation: ConsultationHistory, db: Session = Depends(get_db)):
    """상담 요청"""
    try:
        consultation = await request_consultation_service(consultation, db=db)
        if consultation:
            response = JSONResponse(status_code=200, content=consultation)
            return response
        else:
            raise HTTPException(status_code=404, detail="Consultation not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))