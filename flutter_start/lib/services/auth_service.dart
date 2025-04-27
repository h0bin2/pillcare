// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:8000';  // FastAPI 서버 주소
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // 토큰 저장
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // 토큰 가져오기
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;
    
    // 서버에 토큰 유효성 확인
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/validate-token'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('토큰 검증 오류: $e');
      return false;
    }
  }

  // 로그아웃
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  // 카카오 로그인
  static Future<bool> loginWithKakao() async {
    try {
      // 실제 카카오 로그인 구현시 kakao_flutter_sdk 사용
      // 현재는 더미 데이터로 대체
      
      // 백엔드 서버로 카카오 정보 전송 (더미 데이터)
      final response = await http.post(
        Uri.parse('$baseUrl/api/login/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kakao_token': 'dummy_token',
          'kakao_id': '12345',
          'kakao_name': '사용자',
          'kakao_email': 'user@example.com',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // 서버에서 받은 JWT 토큰 저장
        await saveToken(data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('카카오 로그인 에러: $e');
      return false;
    }
  }

  // 이메일/비밀번호 로그인 (선택적)
  static Future<bool> loginWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('이메일 로그인 에러: $e');
      return false;
    }
  }
}