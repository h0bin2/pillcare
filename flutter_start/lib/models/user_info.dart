// TODO Implement this library.
class UserInfo {
  final int id;
  final String kakaoId;
  final String? nickname; // 백엔드 스키마에 따라 nullable 여부 확인 필요
  final String? profileImageUrl; // 카카오 프로필 이미지 URL 추가

  UserInfo({
    required this.id,
    required this.kakaoId,
    this.nickname,
    this.profileImageUrl,
  });

  // JSON 데이터를 UserInfo 객체로 변환하는 팩토리 생성자
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    // 백엔드 응답의 실제 필드 이름 확인 필수!
    return UserInfo(
      id: json['id'] as int? ?? 0,
      kakaoId: json['kakao_id'] as String? ?? 'unknown_kakao_id',
      nickname: json['nickname'] as String?,
      profileImageUrl: json['profile_image_url'] as String?
        ?? json['kakao_profile_image_url'] as String?, // 둘 중 하나라도 있으면 할당
    );
  }
}

