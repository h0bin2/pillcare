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
from db.crud import insert_record, insert_record_detail
from services.pill_service import get_pill_info_detail, search_pill

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

async def create_record(user_id: int, original_image: UploadFile = File(...)):
    """레코드 생성"""
    try:
        if original_image:
            # 파일 내용을 비동기적으로 읽기 (한 번만)
            contents = await original_image.read()

            # --- 파일 저장 로직 ---
            save_dir = "flutter-back/original_images"
            os.makedirs(save_dir, exist_ok=True)
            original_image_path = os.path.join(save_dir, original_image.filename)
            async with aiofiles.open(original_image_path, "wb") as f:
                await f.write(contents) # 읽어둔 contents 사용
            # -----------------------

            # inference 함수 호출 시 UploadFile 대신 읽어둔 contents(bytes) 전달
            inference_result = await inference(contents)

            # 결과 처리 로직
            if not inference_result or not hasattr(inference_result[0], 'boxes') or inference_result[0].boxes is None:
                print("No objects detected or unexpected result format.")
                # 파일은 저장되었으므로, 결과 없음 상태를 DB에 기록할지 결정 필요
                return {"class_name": [], "boxes": [], "saved_path": original_image_path}

            class_name = inference_result[0].boxes.cls
            boxes = inference_result[0].boxes.xyxy
            kr_name = inference_result[0].names # 모델의 클래스 이름 딕셔너리

            class_name_list = []
            boxes_list = []
            pill_info_list = []
            # 감지된 객체가 있는지 확인 (cls와 xyxy가 None이 아님)
            if class_name is not None and boxes is not None:
                for i in range(len(class_name)):
                    try:
                        # 클래스 ID를 int로 변환하여 이름 찾기
                        cls_id = int(class_name[i].item()) # .item() 추가
                        class_name_list.append(kr_name[cls_id])
                        # 박스 텐서를 리스트로 변환하여 추가
                        boxes_list.append(boxes[i].tolist()) # .tolist() 추가
                        pill_info = search_pill(kr_name[cls_id])
                        print(kr_name[cls_id], pill_info)
                        # pill_info_list.append(search_pill(kr_name[cls_id]))
                    except (KeyError, ValueError, IndexError) as e:
                         print(f"Error processing detection {i}: {e}. Class ID: {class_name[i]}, Box: {boxes[i]}")
                         # 오류 발생 시 처리 (예: 건너뛰거나 기본값 사용)
                         pass # 일단 건너뛰기

            # DB 저장 로직 추가 필요 (original_image_path 포함)
            # await insert_record(user_id, original_image_path, class_name_list, boxes_list)
            return {
                "class_name": class_name_list, # 이제 문자열 리스트
                "boxes": boxes_list,        # 이제 숫자 리스트들의 리스트
                "pill_info": pill_info_list
            }
        else:
            return False # 이미지가 없는 경우
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))