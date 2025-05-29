from db.models import records, record_details
from schemas.schemas import Record, UserInfo
from fastapi import Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from cv import yolo_model
from datetime import datetime
import io
from PIL import Image
import traceback # 상세 오류 출력을 위해 추가
import aiofiles # aiofiles 임포트
import os # os 임포트
from collections import Counter # Counter 추가
from db.crud import insert_record, insert_record_detail, get_pill_info
from services.pill_service import get_pill_info_detail, search_pill
from db.database import get_db

def _group_and_count_class_names(class_name_list: list[str]) -> dict[str, int]:
    """주어진 클래스 이름 리스트에서 각 이름의 개수를 세어 딕셔너리로 반환합니다."""
    if not class_name_list:
        return {}
    return dict(Counter(class_name_list))

# inference 함수: UploadFile 대신 bytes를 받도록 수정
async def inference(image_bytes: bytes): # 매개변수 타입 변경
    """ 이미지 추론 """
    try:
        # 전달받은 bytes 데이터를 직접 사용
        img = Image.open(io.BytesIO(image_bytes))
        output = yolo_model.predict(img)
        return output
    except Exception as e:
        print(f"Error during inference: {e}")
        # Pillow가 이미지 식별 못하는 경우 포함하여 오류 처리
        raise HTTPException(status_code=500, detail=f"Error during image inference: {e}")

async def create_record(user_id: int, original_image: UploadFile = File(...), db: Session = Depends(get_db)):
    record_id = None
    message_on_no_detection = None
    class_name_list = [] # 항상 초기화
    boxes_list = []      # 항상 초기화

    try:
        if not original_image or not original_image.filename:
            raise HTTPException(status_code=400, detail="No image provided or image has no filename.")

        contents = await original_image.read()
        save_dir = "original_images"
        os.makedirs(save_dir, exist_ok=True)
        original_image_path = os.path.join(save_dir, original_image.filename)
        async with aiofiles.open(original_image_path, "wb") as f:
            await f.write(contents)

        inference_result = await inference(contents)

        if not inference_result or not hasattr(inference_result[0], 'boxes') or inference_result[0].boxes is None:
            print("No objects detected or unexpected result format.")
            message_on_no_detection = "No objects detected"
            # class_name_list, boxes_list는 이미 빈 리스트로 초기화됨
        else:
            class_names_tensor = inference_result[0].boxes.cls
            boxes_tensor = inference_result[0].boxes.xyxy
            model_names_dict = inference_result[0].names

            if class_names_tensor is not None and boxes_tensor is not None:
                for i in range(len(class_names_tensor)):
                    try:
                        cls_id = int(class_names_tensor[i].item())
                        detected_pill_name = model_names_dict[cls_id]
                        class_name_list.append(detected_pill_name)
                        current_box = boxes_tensor[i].tolist()
                        boxes_list.append(current_box)
                    except (KeyError, ValueError, IndexError) as e:
                        print(f"Error processing detection {i}: {e}. Class ID: {class_names_tensor[i]}, Box: {boxes_tensor[i]}")
                        pass 
        
        # DB 저장 로직: record_id 생성은 항상 시도 (알약 감지 여부와 무관하게)
        try:
            record_id = await insert_record(user_id=user_id, original_image_path=original_image_path, db=db)
            if not record_id:
                raise HTTPException(status_code=500, detail="Failed to create record in DB (no record_id returned).")
            
            print(f"Record created with ID: {record_id}")

            if class_name_list: # 감지된 알약이 있을 경우에만 상세 정보 저장
                await insert_record_detail(record_id=record_id, class_name_list=class_name_list, boxes_list=boxes_list)
                print(f"Record details saved for Record ID: {record_id}")
            elif message_on_no_detection: # 알약이 없고, 미감지 메시지가 설정된 경우
                print(f"No pill objects detected for Record ID: {record_id}. No details saved.")
            else: # 알약도 없고, 미감지 메시지도 없는 이상한 경우 (이론상 발생 안해야 함)
                print(f"No pill objects and no detection message for Record ID: {record_id}. No details saved.")

        except HTTPException as http_exc:
            raise http_exc # DB 저장 중 발생한 HTTP 예외는 그대로 전달
        except Exception as db_exc:
            traceback.print_exc()
            # DB 저장 실패 시 record_id가 None일 것이므로, 이 record_id를 포함한 오류는 필요 없음
            raise HTTPException(status_code=500, detail=f"Error saving record to database: {str(db_exc)}")

        grouped_class_names = _group_and_count_class_names(class_name_list)
        
        response_data = {
            "id": record_id, 
            "class_name": grouped_class_names
        }
        
        if message_on_no_detection:
             response_data["message"] = message_on_no_detection
        print(f"Response data: {response_data}")
        return response_data

    except HTTPException as e:
        # 이미 처리된 HTTPException은 그대로 발생
        raise e
    except Exception as e:
        traceback.print_exc()
        # 이 지점에서의 예외는 record_id가 확정되기 전이거나 매우 일반적인 오류일 가능성이 높음
        # record_id를 포함한 오류 메시지는 불필요하거나 부정확할 수 있음
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred in create_record: {str(e)}")