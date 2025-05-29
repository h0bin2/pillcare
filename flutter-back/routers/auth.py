# flutter-back/routers/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from schemas.schemas import KakaoToken, Token, UserInfo, RefreshTokenRequest # 스키마 임포트
# 서비스 함수들 임포트
from services.auth_service import (
    create_access_token,
    create_refresh_token,
    get_kakao_user_info,
    get_current_user, # JWT 검증 및 기본 정보 제공 (DB 조회는 여기서 안 함)
    verify_token,
    ACCESS_TOKEN_EXPIRE_MINUTES, # 설정값 가져오기
    REFRESH_TOKEN_EXPIRE_DAYS
)
# DB CRUD 함수 임포트
from db.crud import get_or_create_user, get_user_by_kakao_id
from datetime import timedelta
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from db.database import get_db

router = APIRouter(
    prefix="/api/auth", # API 경로 접두사 설정
    tags=["Authentication"], # API 문서 태그 설정
)

@router.post("/kakao")
async def kakao_login_for_access_token(token_data: KakaoToken, db: Session = Depends(get_db)) -> JSONResponse:
    """
    카카오 토큰을 받아 사용자 정보를 확인하고, DB에서 사용자를 조회/생성한 후
    JWT Access Token과 Refresh Token을 발급합니다.
    """
    try:
        kakao_user_info = await get_kakao_user_info(token_data.kakao_access_token)

        kakao_id = str(kakao_user_info.get("id")) # 문자열로 통일
        properties = kakao_user_info.get("kakao_account", {}).get("profile", {})
        nickname = properties.get("nickname")
        # profile_image_url 필드 확인 (카카오 응답 기준)
        profile_image_url = properties.get("profile_image_url")

        if not kakao_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="카카오 사용자 ID를 가져올 수 없습니다."
            )

        # --- DB에서 사용자 조회 또는 생성 --- 
        db_user = get_or_create_user(
            kakao_id=kakao_id,
            nickname=nickname,
            profile_image_url=profile_image_url,
            db=db
        )
        # ----------------------------------

        # JWT 페이로드에는 DB에서 가져온 정보 사용 (특히 nickname)
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": db_user.kakao_id, "nickname": db_user.nickname},
            expires_delta=access_token_expires
        )

        refresh_token_expires = timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
        refresh_token = create_refresh_token(
            data={"sub": db_user.kakao_id},
            expires_delta=refresh_token_expires
        )

        return JSONResponse(status_code=200, content={
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer"
        })

    except HTTPException as http_exc:
        return JSONResponse(status_code=http_exc.status_code, content={"detail": http_exc.detail})
    except Exception as e:
        print(f"[Auth Router] 카카오 로그인 오류: {e}")
        return JSONResponse(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, content={"detail": "로그인 처리 중 서버 오류 발생"})

@router.post("/refresh", response_model=Token)
async def refresh_access_token(refresh_request: RefreshTokenRequest, db: Session = Depends(get_db)):
    """Refresh Token을 사용하여 새로운 Access Token과 Refresh Token을 발급합니다."""
    try:
        payload = verify_token(refresh_request.refresh_token, token_type="refresh")
        kakao_id: str = payload.get("sub")
        if kakao_id is None:
            return JSONResponse(status_code=status.HTTP_401_UNAUTHORIZED, content={"detail": "Invalid refresh token payload"})

        # --- DB에서 사용자 정보 조회 (Access Token 페이로드용) --- 
        db_user = await get_user_by_kakao_id(kakao_id=kakao_id, db=db)
        if not db_user:
             # Refresh Token은 유효하지만 DB에 사용자가 없는 경우 (비정상 상태)
             print(f"경고: 유효한 Refresh Token의 사용자({kakao_id})를 DB에서 찾을 수 없음.")
             raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found for refresh token.")
        # ----------------------------------------------------- 

        new_access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        new_access_token = create_access_token(
            data={"sub": db_user.kakao_id, "nickname": db_user.nickname},
            expires_delta=new_access_token_expires
        )

        new_refresh_token_expires = timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
        new_refresh_token = create_refresh_token(
            data={"sub": db_user.kakao_id},
            expires_delta=new_refresh_token_expires
        )

        return JSONResponse(status_code=200, content={
            "access_token": new_access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer"
        })

    except HTTPException as http_exc:
        if http_exc.status_code == 401:
            return JSONResponse(status_code=status.HTTP_401_UNAUTHORIZED, content={"detail": "Refresh token invalid or expired. Please log in again."})
        raise http_exc
    except Exception as e:
        print(f"[Auth Router] 토큰 갱신 중 예상치 못한 오류: {e}")
        return JSONResponse(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, content={"detail": "Token refresh failed"})

@router.get("/users/me", response_model=UserInfo)
async def read_current_user_info(current_user: UserInfo = Depends(get_current_user)):
    """
    현재 로그인된 사용자(Access Token 기반)의 정보를 DB에서 조회하여 반환합니다.
    (get_current_user 의존성이 DB 조회를 포함하도록 수정됨)
    """
    # get_current_user 함수가 DB 조회 후 UserInfo 모델을 반환
    return current_user

