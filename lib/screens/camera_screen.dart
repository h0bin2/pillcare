import 'dart:convert'; // jsonDecode를 위해 추가
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // kDebugMode
import '../services/record_service.dart'; // RecordService 임포트
import 'main_screen.dart'; // MainScreen 임포트

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isInitialized = false;
  bool _cameraPermissionDenied = false;
  bool _noCamerasAvailable = false;
  bool _isUploading = false;

  XFile? _imageAfterCapture;
  bool _serverUploadSuccess = false;
  bool _showActionButtons = false;
  String? _serverResponseMessage;

  Map<String, int>? _detectedPillInfo;
  bool _showPillInfoOverlay = false;
  int? _currentRecordId; // 서버로부터 받은 record_id 저장

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        if (!mounted) return;
        setState(() { _noCamerasAvailable = true; _isInitialized = false; });
        return;
      }
      _controller = CameraController( cameras![0], ResolutionPreset.medium, enableAudio: false );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() { _isInitialized = true; _noCamerasAvailable = false; _cameraPermissionDenied = false; });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialized = false;
        if (e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt') {
          _cameraPermissionDenied = true;
        } else {
          _noCamerasAvailable = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isInitialized = false; _noCamerasAvailable = true; });
    }
  }

  Future<void> _handleCancelAction() async {
    if (_currentRecordId != null) {
      if (kDebugMode) {
        print("취소: 서버에 생성된 레코드 ID ${_currentRecordId} 삭제 시도...");
      }
      try {
        bool deleteSuccess = await RecordService.deleteRecord(_currentRecordId!);
        if (deleteSuccess) {
          if (kDebugMode) print("레코드 ID ${_currentRecordId} 삭제 성공.");
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('작업이 취소되고 이전 기록이 삭제되었습니다.')),
            );
          }
        } else {
          if (kDebugMode) print("레코드 ID ${_currentRecordId} 삭제 실패 (서버 응답).");
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('작업 취소 중 이전 기록 삭제에 실패했습니다.')),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) print("레코드 삭제 중 예외 발생: $e");
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('작업 취소 중 오류 (삭제 요청 실패): ${e.toString()}')),
          );
        }
      }
    }
    _resetCameraStateAndPreview();
  }

  void _resetCameraStateAndPreview() {
    setState(() {
      _isUploading = false;
      _imageAfterCapture = null;
      _serverUploadSuccess = false;
      _showActionButtons = false;
      _serverResponseMessage = null;
      _detectedPillInfo = null;
      _showPillInfoOverlay = false;
      _currentRecordId = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy.MM.dd(E)', 'ko').format(DateTime.now());

    if (_cameraPermissionDenied) {
      return const Scaffold(
          body: Center(child: Text('카메라 권한이 거부되었습니다.\n앱 설정에서 권한을 허용해주세요.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black)))); // 검은 배경이므로 글자색 변경
    }

    if (_noCamerasAvailable && !_isInitialized) {
      return const Scaffold(body: Center(child: Text('사용 가능한 카메라가 없습니다.', style: TextStyle(color: Colors.black)))); // 검은 배경이므로 글자색 변경
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            today,
                            style: const TextStyle( color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: (_isInitialized && _controller != null && _controller!.value.isInitialized)
                      ? ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.previewSize?.height ?? MediaQuery.of(context).size.width,
                        height: _controller!.value.previewSize?.width ?? MediaQuery.of(context).size.height,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  )
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                if (!_showPillInfoOverlay)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
                    child: GestureDetector(
                      onTap: (_isUploading || _controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture)
                          ? null
                          : () async {
                        setState(() {
                          _isUploading = true;
                          _serverResponseMessage = null;
                          _detectedPillInfo = null;
                          _currentRecordId = null;
                        });
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('사진을 촬영하고 업로드를 시작합니다...')),
                        );

                        try {
                          final XFile file = await _controller!.takePicture();
                          setState(() { _imageAfterCapture = file; });

                          final response = await RecordService.uploadImage(file);

                          if (!mounted) return;

                          if (response != null && response['error'] == null) {
                            final Map<String, dynamic> responseData = response;
                            // record_id는 항상 받아오도록 서버 응답이 설계되었다고 가정
                            _currentRecordId = responseData['id'] as int?;

                            if (responseData.containsKey('class_name') && responseData['class_name'] is Map &&
                                (responseData['class_name'] as Map).isNotEmpty && _currentRecordId != null) {
                              setState(() {
                                _serverUploadSuccess = true;
                                _detectedPillInfo = Map<String, int>.from(responseData['class_name']);
                                _serverResponseMessage = '약물 정보가 확인되었습니다.';
                              });
                            } else {
                              setState(() {
                                _serverUploadSuccess = false;
                                _serverResponseMessage = responseData['message']?.toString() ?? '감지된 약물이 없거나 서버 처리에 실패했습니다.';
                              });
                            }
                          } else {
                            String errorMessage = response?['message']?.toString() ?? response?['detail']?.toString() ?? '알 수 없는 서버 오류';
                            if (response?['statusCode'] != null) {
                              errorMessage = "서버 오류 (${response!['statusCode']}): $errorMessage";
                            }
                            setState(() {
                              _serverUploadSuccess = false;
                              _serverResponseMessage = errorMessage;
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _serverUploadSuccess = false;
                            _serverResponseMessage = '오류 발생: ${e.toString()}';
                          });
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isUploading = false;
                              _showPillInfoOverlay = true;
                            });
                          }
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _isUploading ? Colors.grey : Colors.white, width: 5),
                          color: Colors.transparent,
                        ),
                        child: _isUploading
                            ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Container(),
                      ),
                    ),
                  ),
                if (_showPillInfoOverlay)
                  const SizedBox(height: 72 + 32 + 16),
              ],
            ),

            if (_isUploading && !_showPillInfoOverlay)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('사진을 업로드 중입니다...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),

            if (_showPillInfoOverlay && !_isUploading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Align(
                    alignment: Alignment.center,
                    child: Card(
                      color: Colors.grey[800],
                      margin: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              _serverUploadSuccess ? '감지된 약물 정보' : '알림',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            if (_serverUploadSuccess && _detectedPillInfo != null && _detectedPillInfo!.isNotEmpty)
                              ..._detectedPillInfo!.entries.map((entry) =>
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Text('${entry.key}: ${entry.value}개', style: const TextStyle(fontSize: 16, color: Colors.white)),
                                  ))
                            else if (_serverResponseMessage != null)
                              Text(_serverResponseMessage!, style: const TextStyle(fontSize: 16, color: Colors.white), textAlign: TextAlign.center),

                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                ElevatedButton(
                                  onPressed: _handleCancelAction,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
                                  child: const Text('취소', style: TextStyle(color: Colors.white)),
                                ),
                                if (_serverUploadSuccess)
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => MainScreen()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                    child: const Text('확인', style: TextStyle(color: Colors.white)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 