# flutter-back/schemas/schemas.py
from pydantic import BaseModel

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
    # 필요에 따라 다른 사용자 정보 필드 추가 가능 