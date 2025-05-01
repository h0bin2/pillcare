// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io'; // Platform 확인용

import 'package:dio/dio.dart'; // dio 임포트
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // PlatformException 사용 위해 추가
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

// --- Custom Exception ---
// 앱 전역에서 사용할 수 있도록 별도 파일로 분리하는 것이 더 좋습니다.
class AuthException implements Exception {
  final String message;
  final int? statusCode; // HTTP 상태 코드 (선택적)
  AuthException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthException: $message (StatusCode: $statusCode)';
}

class AuthService {
  // --- Constants ---
  // 실제 운영 환경에서는 환경 변수 등으로 관리하는 것이 좋습니다.
  static const String _baseUrl = 'http://localhost:8000';
  static const _storage = FlutterSecureStorage();
  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';

  // --- Dio Instances ---
  // 기본 Dio 인스턴스 (인터셉터 포함)
  static final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));
  // 토큰 갱신 전용 Dio 인스턴스 (인터셉터 미포함)
  static final Dio _dioForRefresh = Dio(BaseOptions(baseUrl: _baseUrl));

  // --- Static Constructor / Initializer ---
  // 클래스 로드 시 인터셉터 설정
  static bool _isInterceptorSetup = false;
  static void _setupDioInterceptors() {
    if (_isInterceptorSetup) return;

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // 로그인, 리프레시 요청에는 토큰 추가 안 함
          if (options.path != '/api/auth/kakao' && options.path != '/api/auth/refresh') {
            final accessToken = await _getAccessToken();
            if (accessToken != null) {
              options.headers['Authorization'] = 'Bearer $accessToken';
              print('[Dio Interceptor] Access Token 추가됨: ${options.path}');
            } else {
               print('[Dio Interceptor] Access Token 없음: ${options.path}');
               // 토큰이 꼭 필요한 요청인데 토큰이 없다면 여기서 요청을 중단시킬 수도 있음
               // return handler.reject(DioException(requestOptions: options, message: 'Access Token not found'));
            }
          }
          return handler.next(options); // 요청 계속 진행
        },
        onError: (DioException error, handler) async {
          print('[Dio Interceptor] 에러 발생: ${error.requestOptions.path}, ${error.response?.statusCode}');
          // 401 에러이고, 리프레시 요청이 아닐 경우 토큰 갱신 시도
          if (error.response?.statusCode == 401 && error.requestOptions.path != '/api/auth/refresh') {
            print('[Dio Interceptor] 401 에러 감지, 토큰 갱신 시도...');
            try {
              final refreshed = await refreshToken(); // 토큰 갱신 시도

              if (refreshed) {
                print('[Dio Interceptor] 토큰 갱신 성공, 원래 요청 재시도...');
                // 새 토큰으로 헤더 업데이트
                final newAccessToken = await _getAccessToken();
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                // 원래 요청 재시도 (동일한 dio 인스턴스 사용)
                 final response = await _dio.fetch(error.requestOptions);
                 return handler.resolve(response); // 성공 응답으로 핸들러 종료
              } else {
                // 갱신 실패 시 (refreshToken 내부에서 로그아웃 처리됨)
                print('[Dio Interceptor] 토큰 갱신 실패, 요청 거부.');
                // 로그인 실패로 간주하고 에러 반환 (UI에서 처리하도록)
                 return handler.reject(DioException(
                   requestOptions: error.requestOptions,
                   response: error.response,
                   error: AuthException("Token refresh failed. Please log in again.", statusCode: 401),
                   type: DioExceptionType.unknown // 적절한 타입 설정
                 ));
              }
            } catch (e) {
              print('[Dio Interceptor] 토큰 갱신 중 예외 발생: $e');
              await logout(); // 예외 발생 시 안전하게 로그아웃
              return handler.reject(DioException(
                 requestOptions: error.requestOptions,
                 error: AuthException("An error occurred during token refresh.", statusCode: 500),
                 type: DioExceptionType.unknown
              ));
            }
          }
          // 401 이 아니거나 리프레시 요청 자체에서 에러난 경우 그대로 에러 전달
          return handler.next(error);
        },
      ),
    );
    _isInterceptorSetup = true;
    print('[AuthService] Dio 인터셉터 설정 완료.');
  }

  // --- Token Management ---
  static Future<void> _saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
     print('[AuthService] Access Token 저장됨');
  }

  static Future<String?> _getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<void> _saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
     print('[AuthService] Refresh Token 저장됨');
  }

  static Future<String?> _getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> _deleteAllTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    print('[AuthService] 모든 JWT 토큰 삭제 완료');
  }

  // --- Authentication Status ---
  static Future<bool> isLoggedIn() async {
    _setupDioInterceptors(); // 최초 호출 시 인터셉터 설정 확인
    final token = await _getAccessToken();
    if (token == null) {
      print('[AuthService] isLoggedIn: 로컬 Access Token 없음');
      return false;
    }

    print('[AuthService] isLoggedIn: 로컬 토큰 존재, 백엔드 유효성 검사...');
    try {
      // 보호된 엔드포인트 호출하여 토큰 유효성 검증
      await _dio.get('/api/auth/users/me');
      print('[AuthService] isLoggedIn: 토큰 유효함');
      return true;
    } on DioException catch (e) {
      // 인터셉터가 401 시 갱신 시도 후 실패하면 에러를 반환하므로 여기서 잡힘
      print('[AuthService] isLoggedIn: 토큰 검증 실패 (${e.response?.statusCode}): ${e.message}');
      if (e.response?.statusCode == 401 || e.error is AuthException) {
         // 토큰이 유효하지 않거나 갱신 실패 시 로그아웃 상태로 간주 (logout은 인터셉터/refreshToken에서 처리됨)
         print('[AuthService] isLoggedIn: 유효하지 않은 토큰 또는 갱신 실패');
      } else {
         // 네트워크 오류 등 다른 문제
          print('[AuthService] isLoggedIn: 백엔드 통신 오류');
      }
      return false;
    } catch (e) {
      print('[AuthService] isLoggedIn: 예상치 못한 오류: $e');
      return false;
    }
  }

  // --- Logout ---
  static Future<void> logout() async {
    await _deleteAllTokens();
    try {
      // 카카오 SDK 로그아웃도 시도 (선택적)
      await UserApi.instance.logout();
      print('[AuthService] 카카오 로그아웃 성공');
    } catch (error) {
      print('[AuthService] 카카오 로그아웃 실패 $error');
    }
    print('[AuthService] 로그아웃 완료');
  }

  // --- Kakao Login ---
  static Future<bool> loginWithKakao() async {
    _setupDioInterceptors(); // 인터셉터 설정 확인
    OAuthToken? kakaoToken;
    try {
      // --- 카카오 로그인 시도 ---
      if (await isKakaoTalkInstalled()) {
        try {
          kakaoToken = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') return false;
          // 카톡 실패 시 계정 로그인 시도
          kakaoToken = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        kakaoToken = await UserApi.instance.loginWithKakaoAccount();
      }
      print('[AuthService] 카카오 로그인 성공, AccessToken: ${kakaoToken.accessToken.substring(0, 10)}...');

      // --- 백엔드에 토큰 전송 및 JWT 발급 ---
      print('[AuthService] 백엔드로 카카오 토큰 전송...');
      // 로그인/리프레시 요청에는 인터셉터가 적용되지 않는 _dioForRefresh 사용 가능 (단, 에러 처리는 직접 해야 함)
      // 여기서는 _dio를 사용하되, 인터셉터가 토큰을 추가하지 않도록 경로 확인
      final response = await _dio.post(
        '/api/auth/kakao',
        data: {'kakao_access_token': kakaoToken.accessToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final accessToken = response.data['access_token'];
        final refreshToken = response.data['refresh_token'];

        if (accessToken != null && refreshToken != null) {
          await _saveAccessToken(accessToken);
          await _saveRefreshToken(refreshToken);
          print('[AuthService] 백엔드 토큰 저장 성공');
          return true;
        } else {
           throw AuthException('백엔드 응답에 토큰 없음');
        }
      } else {
         throw AuthException('백엔드 카카오 로그인 실패', statusCode: response.statusCode);
      }
    } catch (e) {
      print('[AuthService] 로그인 과정 중 오류 발생: $e');
      await logout(); // 실패 시 안전하게 로그아웃
      // UI에 에러 전달 위해 AuthException rethrow 가능
      // if (e is DioException) { ... } else if (e is PlatformException) { ... }
      return false;
    }
  }

  // --- Token Refresh ---
  static Future<bool> refreshToken() async {
    _setupDioInterceptors(); // 인터셉터 설정 확인
    final storedRefreshToken = await _getRefreshToken();
    if (storedRefreshToken == null) {
      print('[AuthService] refreshToken: 저장된 Refresh Token 없음');
      return false;
    }

    print('[AuthService] refreshToken: Access Token 갱신 시도...');
    try {
      // 토큰 갱신에는 인터셉터 없는 Dio 인스턴스 사용
      final response = await _dioForRefresh.post(
        '/api/auth/refresh',
        data: {'refresh_token': storedRefreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];

        if (newAccessToken != null && newRefreshToken != null) {
          await _saveAccessToken(newAccessToken);
          await _saveRefreshToken(newRefreshToken);
          print('[AuthService] refreshToken: 토큰 갱신 및 저장 성공');
          return true;
        } else {
          throw AuthException('토큰 갱신 응답에 토큰 없음');
        }
      } else {
         throw AuthException('토큰 갱신 실패', statusCode: response.statusCode);
      }
    } catch (e) {
      print('[AuthService] refreshToken: 오류 발생: $e');
      await logout(); // 갱신 실패 시 강제 로그아웃
      return false;
    }
  }

  // --- Get User Info (Protected API Example) ---
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
     _setupDioInterceptors(); // 인터셉터 설정 확인
     print('[AuthService] getCurrentUserInfo: 사용자 정보 요청 시도...');
    try {
      // 인터셉터가 토큰 추가 및 401 시 갱신/재시도를 처리
      final response = await _dio.get('/api/auth/users/me');

      if (response.statusCode == 200 && response.data is Map) {
         print('[AuthService] getCurrentUserInfo: 사용자 정보 수신 성공: ${response.data}');
        return response.data as Map<String, dynamic>;
      } else {
         // 인터셉터에서 처리되지 않은 오류 (예: 5xx)
         print('[AuthService] getCurrentUserInfo: 예상치 못한 응답 (${response.statusCode})');
         return null;
      }
    } on DioException catch (e) {
       // 인터셉터에서 최종적으로 처리 못한 에러 (갱신 실패 등)
       print('[AuthService] getCurrentUserInfo: 요청 실패 (DioException): ${e.message}');
       // AuthException은 인터셉터에서 생성될 수 있음
       if (e.error is AuthException) {
         print('[AuthService] getCurrentUserInfo: 인증 오류 발생 ${e.error}');
       }
       return null;
    } catch (e) {
       print('[AuthService] getCurrentUserInfo: 예상치 못한 오류: $e');
       return null;
    }
  }

  // --- Email/Password Login (Placeholder) ---
  // 필요 없다면 이 함수는 제거해도 됩니다.
  static Future<bool> loginWithEmail(String email, String password) async {
    _setupDioInterceptors();
    print('[AuthService] 이메일 로그인은 현재 구현되지 않았습니다.');
    // TODO: 백엔드에 이메일 로그인 API 구현 후 연동 (/api/auth/login 등)
    // final response = await _dio.post('/api/auth/login', data: {'username': email, 'password': password});
    // 토큰 처리 로직 필요...
    return false;
  }
}