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
from db.database import get_db

router = APIRouter(prefix="/api/record", tags=["record"])

@router.post("/insert", response_model=Record)
async def create_record_api(original_image: UploadFile = File(...), user: UserInfo = Depends(get_current_user), db: Session = Depends(get_db)):
    """레코드 생성 API"""
    if user.id is None:
        raise HTTPException(status_code=400, detail="User ID is missing")
    
    created_record_data = create_record(user_id=user.id, original_image=original_image, db=db)
    
    return created_record_data

@router.get("/read", response_model=List[RecordRead])
async def read_record_api(user: UserInfo = Depends(get_current_user), db: Session = Depends(get_db)):
    """사용자의 모든 레코드와 상세 약물 정보 조회"""
    if user.id is None:
        raise HTTPException(status_code=400, detail="User ID is missing")
    try:
        user_records_with_details = crud.get_records_with_details_by_user_id(user_id=user.id, db=db)
        return user_records_with_details
    except Exception as e:
        print(f"Error reading records for user {user.id}: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"An error occurred while reading records: {str(e)}")

@router.delete("/delete")
async def delete_record_api(record_id: int = Query(..., description="삭제할 레코드의 ID"), user: UserInfo = Depends(get_current_user), db: Session = Depends(get_db)):
    """레코드 삭제"""
    if user.id is None:
        raise HTTPException(status_code=400, detail="User ID is missing")
    try:
        delete_details_success = crud.delete_record_details_by_record_id(record_id=record_id, db=db)
        if not delete_details_success:
            print(f"Warning: Failed to delete details for record_id {record_id}, but proceeding to delete the main record.")

        delete_record_success = crud.delete_record_by_id(record_id=record_id, db=db)

        if delete_record_success:
            return {"message": f"Record id {record_id} deleted successfully"}
        else:
            raise HTTPException(status_code=404, detail=f"Record id {record_id} not found or could not be deleted")

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"Error deleting record id {record_id}: {e}")
        raise HTTPException(status_code=500, detail=f"An error occurred while deleting record id {record_id}.")
    
@router.delete("/pill_delete")
async def delete_pill_api(record_id: int = Query(..., description="삭제할 레코드의 ID"), pill_id: int = Query(..., description="삭제할 약품의 ID"), user: UserInfo = Depends(get_current_user), db: Session = Depends(get_db)):
    """약품 삭제"""
    if user.id is None:
        raise HTTPException(status_code=400, detail="User ID is missing")
    
    try:
        delete_pill_success = crud.delete_pill_by_id(record_id=record_id, pill_id=pill_id, db=db)
        if delete_pill_success:
            return {"message": f"Pill id {pill_id} deleted successfully"}
        else:
            raise HTTPException(status_code=404, detail=f"Pill id {pill_id} not found or could not be deleted")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(f"Error deleting pill id {pill_id}: {e}")
        raise HTTPException(status_code=500, detail=f"An error occurred while deleting pill id {pill_id}.")