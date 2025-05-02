// lib/services/auth_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:convert';

import 'package:http/http.dart' as http;


class AuthService {
  static const String baseUrl = 'http://localhost:8000';  // FastAPI 서버 주소
  static final _storage = FlutterSecureStorage(); //

  static const _tokenKey = 'auth_token';

  // 토큰 저장
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // 토큰 가져오기
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // 로그인 상태 확인 (임시로 항상 false 반환)
  static Future<bool> isLoggedIn() async {
    // TODO: 실제 로그인 상태 확인 로직 구현
    return false;
  }

  // 로그아웃
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  // 카카오 로그인 (임시로 항상 true 반환)
  static Future<bool> loginWithKakao() async {
    // TODO: 실제 카카오 로그인 로직 구현
    return true;
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

  static FlutterSecureStorage() {}
}