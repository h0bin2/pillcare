from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Query
from services.record_service import create_record
from fastapi.responses import JSONResponse
from typing import List
from fastapi import Depends
from services.auth_service import get_current_user
from schemas.schemas import UserInfo, Record, RecordRead
from sqlalchemy.orm import Session
from db import crud
import traceback

router = APIRouter(prefix="/api/record", tags=["record"])

@router.post("/insert", response_model=Record)
async def create_record_api(original_image: UploadFile = File(...), user: UserInfo = Depends(get_current_user)):
    """레코드 생성 API"""
    if user.id is None:
        raise HTTPException(status_code=400, detail="User ID is missing")
    
    created_record_data = await create_record(user_id=user.id, original_image=original_image)
    
    return created_record_data

@router.get("/read", response_model=List[RecordRead])
async def read_record_api(user: UserInfo = Depends(get_current_user)):
    """사용자의 모든 레코드와 상세 약물 정보 조회"""
    if user.id is None:
        raise HTTPException(status_code=400, detail="User ID is missing")
    try:
        user_records_with_details = await crud.get_records_with_details_by_user_id(user_id=user.id)
        return user_records_with_details
    except Exception as e:
        print(f"Error reading records for user {user.id}: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"An error occurred while reading records: {str(e)}")

@router.delete("/delete")
async def delete_record_api(record_id: int = Query(..., description="삭제할 레코드의 ID"), user: UserInfo = Depends(get_current_user)):
    """레코드 삭제"""
    if user.id is None:
        raise HTTPException(status_code=400, detail="User ID is missing")
    try:
        delete_details_success = await crud.delete_record_details_by_record_id(record_id=record_id)
        if not delete_details_success:
            print(f"Warning: Failed to delete details for record_id {record_id}, but proceeding to delete the main record.")

        delete_record_success = await crud.delete_record_by_id(record_id=record_id)

        if delete_record_success:
            return {"message": f"Record id {record_id} deleted successfully"}
        else:
            raise HTTPException(status_code=404, detail=f"Record id {record_id} not found or could not be deleted")

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"Error deleting record id {record_id}: {e}")
        raise HTTPException(status_code=500, detail=f"An error occurred while deleting record id {record_id}.")