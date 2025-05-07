from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from services.record_service import create_record
from fastapi.responses import JSONResponse
from typing import List
from fastapi import Depends
from services.auth_service import get_current_user
from schemas.schemas import UserInfo

router = APIRouter(prefix="/api/record", tags=["record"])

@router.post("/insert")
async def create_record_api(original_image: UploadFile = File(...)):
    """레코드 생성"""
    try:
        if original_image:
            type = original_image.content_type
            if type == "image/jpeg":
                pass
            elif type == "image/png":
                pass
            else:
                raise HTTPException(status_code=400, detail="Invalid image type")
        record = await create_record(0, original_image)
        if record:
            response = JSONResponse(status_code=200, content=record)
            return response
        else:
            raise HTTPException(status_code=404, detail="Record not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
