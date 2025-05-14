
// TODO Implement this library.
class UserInfo {
  final int id;
  final String kakaoId;
  final String? nickname; // 백엔드 스키마에 따라 nullable 여부 확인 필요

  UserInfo({
    required this.id,
    required this.kakaoId,
    this.nickname,
  });

  // JSON 데이터를 UserInfo 객체로 변환하는 팩토리 생성자
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    // 백엔드 응답의 실제 필드 이름 확인 필수!
    return UserInfo(
      id: json['id'] as int? ?? 0,
      kakaoId: json['kakao_id'] as String? ?? 'unknown_kakao_id',
      nickname: json['nickname'] as String?,
    );
  }
}

