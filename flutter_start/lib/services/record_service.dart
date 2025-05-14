import 'dart:io';
import 'package:dio/dio.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart'; // AuthService의 static 멤버(baseUrl, dio 인스턴스) 접근을 위함
import 'dart:convert';

class RecordService {
  static final Dio _dio = AuthService.getDioInstance();

  static Future<Map<String, dynamic>?> uploadImage(XFile imageFile) async {
    String fileName = imageFile.path.split('/').last;
    FormData formData = FormData.fromMap({
      "original_image": await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    if (kDebugMode) {
      print('[RecordService] Uploading image: ${imageFile.path}');
      print('[RecordService] Base URL for upload (Dio): ${_dio.options.baseUrl}');
      print('[RecordService] Target endpoint for upload: /api/record/insert');
    }

    try {
      final response = await _dio.post(
        '/api/record/insert',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (kDebugMode) {
          print('[RecordService] Image upload successful: ${response.data}');
        }
        return response.data as Map<String, dynamic>;
      } else {
        if (kDebugMode) {
          print('[RecordService] Image upload failed: ${response.statusCode}, ${response.data}');
        }
        return {'error': 'Upload failed', 'statusCode': response.statusCode, 'detail': response.data};
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[RecordService] Image upload DioException: ${e.message}');
        if (e.response != null) {
          print('[RecordService] DioException response: ${e.response?.data}');
        }
      }
      return {'error': 'DioException', 'message': e.message, 'detail': e.response?.data};
    } catch (e) {
      if (kDebugMode) {
        print('[RecordService] Image upload Exception: $e');
      }
      return {'error': 'Exception', 'message': e.toString()};
    }
  }

  static Future<bool> deleteRecord(int recordId) async {
    final String endpoint = '/api/record/delete';

    if (kDebugMode) print('Attempting to delete record ID: $recordId using Dio at $endpoint?record_id=$recordId');

    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: {'record_id': recordId},
      );

      if (kDebugMode) {
        print('Delete response status (Dio): ${response.statusCode}');
        print('Delete response data (Dio): ${response.data}');
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        print('[RecordService] Delete request returned status ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error deleting record (DioException): ${e.message}');
        if (e.response != null) {
          print('DioException response for delete: ${e.response?.data}');
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error deleting record (General Exception): $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>?> getRecords() async {
    const String endpoint = '/api/record/read';

    if (kDebugMode) print('Attempting to fetch records using Dio at $endpoint');

    try {
      final response = await _dio.get(endpoint);

      if (kDebugMode) {
        print('Fetch records response status (Dio): ${response.statusCode}');
      }

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          List<Map<String, dynamic>> records = List<Map<String, dynamic>>.from(
              response.data.map((item) {
                if (item is Map) {
                  return Map<String, dynamic>.from(item);
                } else {
                  print('[RecordService] Unexpected item type in record list: ${item.runtimeType}');
                  return <String, dynamic>{};
                }
              })
          );
           if (kDebugMode) {
             print('[RecordService] Fetched ${records.length} records.');
           }
          return records;
        } else {
           if (kDebugMode) {
             print('[RecordService] Fetched records data is not a List: ${response.data.runtimeType}');
           }
           return null;
        }
      } else {
        print('[RecordService] Fetch records request returned status ${response.statusCode}');
        return null;
      }

    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error fetching records (DioException): ${e.message}');
        if (e.response != null) {
          print('DioException response for fetch records: ${e.response?.data}');
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error fetching records (General Exception): $e');
      return null;
    }
  }
} 