// lib/services/auth_service.dart

import 'dart:io'; // Platform 확인용

import 'package:dio/dio.dart'; // dio 임포트
import 'package:flutter/foundation.dart'; // kDebugMode 사용
import 'package:flutter/services.dart'; // PlatformException 사용 위해 추가
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../models/user_info.dart'; // UserInfo 모델
import '../models/consultation_info.dart'; // ConsultationInfo 모델

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
  static const String _baseUrl = 'http://192.168.45.208:5555';
  static final _storage = const FlutterSecureStorage();
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
              if (kDebugMode) print('[Dio Interceptor] Access Token 추가됨: ${options.path}');
            } else {
              if (kDebugMode) print('[Dio Interceptor] Access Token 없음: ${options.path}');
            }
          }
          return handler.next(options); // 요청 계속 진행
        },
        onError: (DioException error, handler) async {
          if (kDebugMode) print('[Dio Interceptor] 에러 발생: ${error.requestOptions.path}, ${error.response?.statusCode}');
          // 401 에러이고, 리프레시 요청이 아닐 경우 토큰 갱신 시도
          if (error.response?.statusCode == 401 && error.requestOptions.path != '/api/auth/refresh') {
            if (kDebugMode) print('[Dio Interceptor] 401 에러 감지, 토큰 갱신 시도...');
            try {
              final refreshed = await refreshToken(); // 토큰 갱신 시도

              if (refreshed) {
                if (kDebugMode) print('[Dio Interceptor] 토큰 갱신 성공, 원래 요청 재시도...');
                // 새 토큰으로 헤더 업데이트
                final newAccessToken = await _getAccessToken();
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                // 원래 요청 재시도 (동일한 dio 인스턴스 사용)
                 final response = await _dio.fetch(error.requestOptions);
                 return handler.resolve(response); // 성공 응답으로 핸들러 종료
              } else {
                // 갱신 실패 시 (refreshToken 내부에서 로그아웃 처리됨)
                if (kDebugMode) print('[Dio Interceptor] 토큰 갱신 실패, 요청 거부.');
                // 로그인 실패로 간주하고 에러 반환 (UI에서 처리하도록)
                 return handler.reject(DioException(
                   requestOptions: error.requestOptions,
                   response: error.response,
                   error: AuthException("Token refresh failed. Please log in again.", statusCode: 401),
                   type: DioExceptionType.unknown // 적절한 타입 설정
                 ));
              }
            } catch (e) {
              if (kDebugMode) print('[Dio Interceptor] 토큰 갱신 중 예외 발생: $e');
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
    if (kDebugMode) print('[AuthService] Dio 인터셉터 설정 완료.');
  }

  // --- Token Management ---
  static Future<void> _saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
    if (kDebugMode) print('[AuthService] Access Token 저장됨');
  }


  static Future<String?> _getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<void> _saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
    if (kDebugMode) print('[AuthService] Refresh Token 저장됨');
  }

  static Future<String?> _getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> _deleteAllTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    if (kDebugMode) print('[AuthService] 모든 JWT 토큰 삭제 완료');
  }

  // --- Authentication Status ---
  static Future<bool> isLoggedIn() async {
    _setupDioInterceptors(); // 최초 호출 시 인터셉터 설정 확인
    final token = await _getAccessToken();
    if (token == null) {
      if (kDebugMode) print('[AuthService] isLoggedIn: 로컬 Access Token 없음');
      return false;
    }

    if (kDebugMode) print('[AuthService] isLoggedIn: 로컬 토큰 존재, 백엔드 유효성 검사...');
    try {
      // 보호된 엔드포인트 호출하여 토큰 유효성 검증
      await _dio.get('/api/auth/users/me');
      if (kDebugMode) print('[AuthService] isLoggedIn: 토큰 유효함');
      return true;
    } on DioException catch (e) {
      // 인터셉터가 401 시 갱신 시도 후 실패하면 에러를 반환하므로 여기서 잡힘
      if (kDebugMode) print('[AuthService] isLoggedIn: 토큰 검증 실패 (${e.response?.statusCode}): ${e.message}');
      if (e.response?.statusCode == 401 || e.error is AuthException) {
         // 토큰이 유효하지 않거나 갱신 실패 시 로그아웃 상태로 간주 (logout은 인터셉터/refreshToken에서 처리됨)
         if (kDebugMode) print('[AuthService] isLoggedIn: 유효하지 않은 토큰 또는 갱신 실패');
      } else {
         // 네트워크 오류 등 다른 문제
          if (kDebugMode) print('[AuthService] isLoggedIn: 백엔드 통신 오류');
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('[AuthService] isLoggedIn: 예상치 못한 오류: $e');
      return false;
    }
  }

  // --- Logout ---
  static Future<void> logout() async {
    await _deleteAllTokens();
    try {
      // 카카오 SDK 로그아웃도 시도 (선택적)
      await UserApi.instance.logout();
      if (kDebugMode) print('[AuthService] 카카오 로그아웃 성공');
    } catch (error) {
      if (kDebugMode) print('[AuthService] 카카오 로그아웃 실패 $error');
    }
    if (kDebugMode) print('[AuthService] 로그아웃 완료');
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
      if (kDebugMode) {
        print('[AuthService] 카카오 로그인 성공, AccessToken: ${kakaoToken.accessToken.substring(0, 10)}...');
        print('[AuthService] 백엔드로 카카오 토큰 전송...');
      }

      // --- 백엔드에 토큰 전송 및 JWT 발급 ---
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
          if (kDebugMode) print('[AuthService] 백엔드 토큰 저장 성공');
          return true;
        } else {
           throw AuthException('백엔드 응답에 토큰 없음');
        }
      } else {
         throw AuthException('백엔드 카카오 로그인 실패', statusCode: response.statusCode);
      }
    } catch (e) {
      if (kDebugMode) print('[AuthService] 로그인 과정 중 오류 발생: $e');
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
      if (kDebugMode) print('[AuthService] refreshToken: 저장된 Refresh Token 없음');
      return false;
    }

    if (kDebugMode) print('[AuthService] refreshToken: Access Token 갱신 시도...');
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
          if (kDebugMode) print('[AuthService] Access Token 갱신 및 저장 성공');
          return true;
        } else {
          if (kDebugMode) print('[AuthService] refreshToken: 응답에 새 토큰 없음');
          await logout();
          return false;
        }
      } else {
         throw AuthException('토큰 갱신 실패', statusCode: response.statusCode);
      }
    } catch (e) {
      if (kDebugMode) print('[AuthService] refreshToken: 오류 발생: $e');
      await logout(); // 갱신 실패 시 강제 로그아웃
      return false;
    }
  }

  // --- Get User Info (Protected API Example) ---
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
     _setupDioInterceptors(); // 인터셉터 설정 확인
     if (kDebugMode) print('[AuthService] getCurrentUserInfo: 사용자 정보 요청 시도...');
    try {
      // 인터셉터가 토큰 추가 및 401 시 갱신/재시도를 처리
      final response = await _dio.get('/api/auth/users/me');

      if (response.statusCode == 200 && response.data != null) {
         if (kDebugMode) print('[AuthService] getCurrentUserInfo: 사용자 정보 수신 성공: ${response.data}');
        if (response.data is Map<String, dynamic> && response.data.containsKey('id') && response.data['id'] is int) {
          return response.data as Map<String, dynamic>;
        } else {
          if (kDebugMode) print('[AuthService] getCurrentUserInfo: 응답에 사용자 ID(\'id\') 필드가 없거나 정수형이 아닙니다.');
          throw AuthException('User ID not found or not an integer in user info response.');
        }
      } else {
         // 인터셉터에서 처리되지 않은 오류 (예: 5xx)
         if (kDebugMode) print('[AuthService] getCurrentUserInfo: 예상치 못한 응답 (${response.statusCode})');
         throw AuthException('Failed to load user info', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
       // 인터셉터에서 최종적으로 처리 못한 에러 (갱신 실패 등)
       if (kDebugMode) print('[AuthService] getCurrentUserInfo: DioException - ${e.message}');
       // AuthException은 인터셉터에서 생성될 수 있음
       if (e.error is AuthException) {
         if (kDebugMode) print('[AuthService] getCurrentUserInfo: 인증 오류 발생 ${e.error}');
       }
       throw AuthException('Failed to load user info: ${e.message}', statusCode: e.response?.statusCode);
    } catch (e) {
       if (kDebugMode) print('[AuthService] getCurrentUserInfo: 예상치 못한 오류: $e');
       throw AuthException('An unexpected error occurred while fetching user info: $e');
    }
  }

  // --- Email/Password Login (Placeholder) ---
  // 필요 없다면 이 함수는 제거해도 됩니다.
  static Future<bool> loginWithEmail(String email, String password) async {
    _setupDioInterceptors();
    if (kDebugMode) print('[AuthService] 이메일 로그인은 현재 구현되지 않았습니다.');
    // TODO: 백엔드에 이메일 로그인 API 구현 후 연동 (/api/auth/login 등)
    // final response = await _dio.post('/api/auth/login', data: {'username': email, 'password': password});
    // 토큰 처리 로직 필요...
    return false;
  }

  // --- Consultation History ---
  static Future<List<ConsultationInfo>> getConsultationHistory(int userId) async {
    _setupDioInterceptors();
    if (kDebugMode) print('[AuthService] getConsultationHistory: 사용자 ID $userId 로 상담 내역 요청...');
    try {
      final response = await _dio.get(
        '/api/consultation/history', // FastAPI 라우터 prefix + 엔드포인트
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          final List<dynamic> responseData = response.data as List<dynamic>;
          final List<ConsultationInfo> historyList = responseData
              .map((item) => ConsultationInfo.fromJson(item as Map<String, dynamic>))
              .toList();
          if (kDebugMode) print('[AuthService] getConsultationHistory: 상담 내역 ${historyList.length}건 수신 성공');
          return historyList;
        } else {
          if (kDebugMode) print('[AuthService] getConsultationHistory: 응답 데이터가 List 형태가 아님: ${response.data}');
          throw Exception('Invalid data format from server for consultation history.');
        }
      } else {
        if (kDebugMode) print('[AuthService] getConsultationHistory: 서버 오류 - ${response.statusCode}');
        throw Exception('Failed to load consultation history. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) print('[AuthService] getConsultationHistory: DioException - ${e.message}');
      throw Exception('Failed to load consultation history: ${e.message}');
    } catch (e) {
      if (kDebugMode) print('[AuthService] getConsultationHistory: 예상치 못한 오류 - $e');
      throw Exception('An unexpected error occurred while fetching consultation history: $e');
    }
  }

  // RecordService에서 baseUrl을 참조하기 위한 getter (추가)
  static String getBaseUrl() => _baseUrl;

  // RecordService에서 인터셉터가 적용된 Dio 인스턴스를 참조하기 위한 getter (추가)
  static Dio getDioInstance() {
    _setupDioInterceptors(); // 인터셉터 설정 보장
    return _dio;
  }

  // --- Medicine History ---
  static Future<List<dynamic>> getMedicineHistory() async {
    _setupDioInterceptors();
    if (kDebugMode) print('[AuthService] getMedicineHistory: 약 기록 요청...');
    try {
      final response = await _dio.get('/api/medicine/history');

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          final List<dynamic> medicineList = response.data as List<dynamic>;
          if (kDebugMode) print('[AuthService] getMedicineHistory: 약 기록 ${medicineList.length}건 수신 성공');
          return medicineList;
        } else {
          if (kDebugMode) print('[AuthService] getMedicineHistory: 응답 데이터가 List 형태가 아님: ${response.data}');
          throw Exception('Invalid data format from server for medicine history.');
        }
      } else {
        if (kDebugMode) print('[AuthService] getMedicineHistory: 서버 오류 - ${response.statusCode}');
        throw Exception('Failed to load medicine history. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) print('[AuthService] getMedicineHistory: DioException - ${e.message}');
      throw Exception('Failed to load medicine history: ${e.message}');
    } catch (e) {
      if (kDebugMode) print('[AuthService] getMedicineHistory: 예상치 못한 오류 - $e');
      throw Exception('An unexpected error occurred while fetching medicine history: $e');
    }
  }
}