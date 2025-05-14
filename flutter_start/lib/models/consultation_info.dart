
// TODO Implement this library.

import 'package:intl/intl.dart';

class ConsultationInfo {
  final int id;
  final int userId;
  final int pharmacyId;
  final String pharmacyName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String history;
  // final String? pharmacyPhoneNumber; // FastAPI 스키마에 추가되면 주석 해제

  ConsultationInfo({
    required this.id,
    required this.userId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.history,
    // this.pharmacyPhoneNumber,
  });

  factory ConsultationInfo.fromJson(Map<String, dynamic> json) {
    return ConsultationInfo(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      pharmacyId: json['pharmacy_id'] as int,
      pharmacyName: json['pharmacy_name'] as String? ?? '정보 없음',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? '정보 없음',
      history: json['history'] as String? ?? '내역 없음',
      // pharmacyPhoneNumber: json['pharmacy_phone'] as String?, // FastAPI 스키마에 추가되면 주석 해제
    );
  }

  // 화면 표시용 날짜 포맷팅 유틸리티
  String get formattedCreatedAt {
    return DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(createdAt);
  }
} 

