from fastapi import APIRouter, Depends, HTTPException, status
from services.pill_service import search_pill, get_pill_info_detail
from schemas.schemas import PillInfo, PillInfoDetail
from typing import List

router = APIRouter(prefix="/api/pill", tags=["pill"])

@router.get('/search', response_model=List[PillInfo])
async def get_pill_info_api(search_word: str):
    """약 정보 검색"""
    try:
        # 약 정보 검색
        pill_info = search_pill(search_word)
        return pill_info
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@router.get('/detail', response_model=PillInfoDetail)
async def get_pill_info_detail_api(drug_code: str):
    """약 상세 정보 조회"""
    try:
        pill_info_detail = get_pill_info_detail(drug_code)
        return pill_info_detail
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))