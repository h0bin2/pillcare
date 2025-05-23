# flutter-back/services/auth_service.py
import os
import requests
from datetime import datetime, timedelta, timezone
from fastapi import HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from schemas.schemas import TokenData, UserInfo, RefreshTokenData
from dotenv import load_dotenv
from db.crud import get_user_by_kakao_id
from sqlalchemy.orm import Session
from db.database import get_db

load_dotenv()

# 환경 변수 로드 (main.py와 동일하게 접근)
SECRET_KEY = os.getenv("SECRET_KEY", "default_secret_key_please_change")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
# Refresh Token 만료 시간 (예: 7일)
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", 7))

KAKAO_USERINFO_URL = "https://kapi.kakao.com/v2/user/me"

# OAuth2 설정 (get_current_user에서 사용)
# tokenUrl은 실제 토큰 발급 경로를 참조해야 함 (auth 라우터 경로 고려)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/kakao") # 라우터 경로에 맞게 수정

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    """JWT 액세스 토큰 생성"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"}) # 토큰 타입 명시 (선택적)
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict, expires_delta: timedelta | None = None):
    """JWT 리프레시 토큰 생성"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    # 리프레시 토큰 페이로드에는 최소한의 정보만 포함 (예: sub)
    to_encode = {"sub": data.get("sub"), "exp": expire, "type": "refresh"} # 타입 명시
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_kakao_user_info(kakao_access_token: str) -> dict:
    """카카오 액세스 토큰으로 카카오 사용자 정보 조회"""
    headers = {"Authorization": f"Bearer {kakao_access_token}"}
    try:
        response = requests.get(KAKAO_USERINFO_URL, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"카카오 API 요청 실패: {e}")
        status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        detail = "카카오 API 서버 연결 실패"
        if e.response is not None:
            status_code = e.response.status_code
            try:
                detail = e.response.json().get('msg', '카카오 API 에러')
                print(f"카카오 API 에러 응답 ({status_code}): {detail}")
                if status_code == 401:
                     detail = "카카오 인증 실패. 토큰을 확인하세요."
                     # 여기서 바로 HTTPException을 raise하면 의존성 주입 등에서 문제 발생 가능
                     # 호출한 쪽(라우터)에서 처리하도록 에러 정보 포함하여 예외 발생 또는 None 반환 고려
                     # 여기서는 간단하게 상세 정보만 포함하여 raise
                     raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail=detail,
                        headers={"WWW-Authenticate": "Bearer"},
                     )
            except ValueError:
                detail = e.response.text
                print(f"카카오 API 에러 응답 파싱 불가 ({status_code}): {detail}")
        # 서비스 함수에서는 특정 HTTP 예외보다 일반 예외나 커스텀 예외를 발생시키는 것이 더 유연할 수 있음
        # 여기서는 일단 HTTPException 유지
        raise HTTPException(status_code=status_code, detail=detail)
    except Exception as e:
         print(f"카카오 사용자 정보 조회 중 예상치 못한 오류: {e}")
         raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="카카오 사용자 정보 조회 오류"
         )


def verify_token(token: str, token_type: str = "access") -> dict:
    """JWT 토큰 (Access 또는 Refresh) 검증 및 페이로드 반환"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=f"Could not validate {token_type} token",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        # 토큰 타입 확인 (선택적이지만 권장)
        if payload.get("type") != token_type:
             print(f"토큰 타입 불일치: 기대값={token_type}, 실제값={payload.get('type')}")
             raise credentials_exception
        # 만료 시간 직접 확인 (decode가 처리하지만 명시적으로 추가 가능)
        # exp = payload.get("exp")
        # if exp is None or datetime.now(timezone.utc) > datetime.fromtimestamp(exp, timezone.utc):
        #     raise credentials_exception
        return payload
    except JWTError as e:
        print(f"{token_type.capitalize()} token decoding error: {e}")
        raise credentials_exception

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> UserInfo:
    """Access Token 검증 후 DB에서 사용자 정보를 조회하여 반환"""
    payload = verify_token(token, token_type="access")
    kakao_id: str = payload.get("sub")
    if kakao_id is None:
        # 페이로드가 유효하지 않은 경우 (이론상 verify_token에서 걸러짐)
         raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid access token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # --- DB에서 사용자 조회 --- 
    user = get_user_by_kakao_id(kakao_id=kakao_id, db=db)
    if user is None:
        # 토큰은 유효하지만 해당 사용자가 DB에 없는 경우 (계정 삭제 등 비정상 상황)
        print(f"경고: 유효한 Access Token의 사용자({kakao_id})를 DB에서 찾을 수 없음.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found for token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    # ------------------------

    # DB에서 조회한 정보를 UserInfo 스키마로 반환
    return user # get_user_by_kakao_id가 이미 UserInfo | None 반환 