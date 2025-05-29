# flutter-back/schemas/schemas.py
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
from datetime import datetime

class KakaoToken(BaseModel):
    """카카오 로그인 시 Flutter 앱에서 받는 토큰 모델"""
    kakao_access_token: str

class Token(BaseModel):
    """클라이언트에게 반환할 JWT 토큰 모델"""
    access_token: str
    refresh_token: str
    token_type: str

class TokenData(BaseModel):
    """JWT 토큰 내부의 데이터(페이로드) 검증용 모델"""
    sub: str | None = None  # 사용자 식별자 (예: 카카오 ID)
    nickname: str | None = None # 닉네임 정보 추가 (선택적)

class RefreshTokenData(BaseModel):
    """Refresh Token 페이로드 검증용 모델"""
    sub: str | None = None # 사용자 식별자만 포함하는 것이 일반적

class RefreshTokenRequest(BaseModel):
    """토큰 갱신 요청 시 클라이언트가 보내는 모델"""
    refresh_token: str

class UserInfo(BaseModel):
    """보호된 엔드포인트에서 반환할 사용자 정보 모델 (예시)"""
    kakao_id: str
    nickname: str | None = None
    id: int | None = None
    kakao_profile_image_url: str | None = None
    # 필요에 따라 다른 사용자 정보 필드 추가 가능 

class PillInfo(BaseModel):
    """약 정보 API 요청에 필요한 모델"""
    drug_code: str
    drug_name: str
    # pack_img: str # DB 모델 확인 필요
    dosage: str
    effect: str    
    
class PillInfoDetail(BaseModel):
    """약 상세 정보 API 요청에 필요한 모델"""
    drug_code: str
    drug_name: str
    # pack_img: str # DB 모델 확인 필요
    dosage: str
    effect: str
    caution: str


class ConsultationHistory(BaseModel):
    """상담 내역 조회 모델"""
    id: Optional[int] = None
    user_id: int
    pharmacy_id: int
    pharmacy_name: str # 약국 이름 (DB 조인 또는 별도 필드 필요)
    pharmacy_address: str
    pharmacy_phone: str
    created_at: datetime
    updated_at: datetime
    status: str
    history: str
    
# --- Record 관련 스키마 수정 ---
class RecordBase(BaseModel):
    """레코드의 기본 필드를 정의 (생성 및 조회 시 공통)"""
    pass

class RecordCreate(RecordBase):
    """레코드 생성 시 사용될 수 있는 스키마 (현재 API에서는 직접적인 요청 본문으로 사용 안 함)"""
    pass

# Record 스키마를 실제 create_record_api의 응답에 맞게 수정
class Record(BaseModel): # BaseModel을 직접 상속
    """레코드 생성 API의 응답 모델"""
    id: int 
    class_name: Dict[str, int]
    message: Optional[str] = None # 알약 미감지 또는 기타 메시지용

    # class Config:
    #     orm_mode = True
    #     # Pydantic V2에서는 from_attributes = True

# 조회 시 레코드 상세에 포함될 개별 약물 정보
class RecordDetailPillInfo(BaseModel):
    pill_id: int
    pill_name: str # 약 이름 (pills 테이블에서 join)
    pill_count: int
    # 필요하다면 effect, dosage 등 pills 테이블의 다른 정보도 추가 가능
    effect: Optional[str] = None
    dosage: Optional[str] = None

# 레코드 조회 API (/read)의 응답 모델
class RecordRead(BaseModel):
    id: int
    user_id: int
    created_at: datetime
    original_image_path: str
    details: List[RecordDetailPillInfo] # 해당 레코드에 포함된 약물 상세 목록

    class Config:
        orm_mode = True # 혹은 from_attributes = True (Pydantic V2)