import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonDecode
import 'package:flutter_naver_map/flutter_naver_map.dart'; // 네이버 지도 패키지
import 'subscription_screen.dart';

class PharmacyScreen extends StatelessWidget {
  const PharmacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 약국 데이터
    final pharmacies = [
      {
        'name': '지성약국',
        'distance': '570m',
        'address': '강릉시 범일로 604, 2층',
        'open': '08:30~18:00',
      },
      {
        'name': '소나무한약국',
        'distance': '0.92km',
        'address': '강릉시 경강로 1951',
        'open': '08:30~18:00',
      },
      {
        'name': '행복한약국',
        'distance': '0.65km',
        'address': '강릉시 구정면 범일로 442',
        'open': '08:30~18:00',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFD954),
                shape: StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () {
                // 전화내역 페이지 이동
              },
              icon: Icon(Icons.phone, color: Colors.black, size: 30),
              label: Text(
                '전화내역',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _PharmacyScreenWithCustomDrag(pharmacies: pharmacies),
    );
  }
}

class _PharmacyScreenWithCustomDrag extends StatefulWidget {
  final List<Map<String, String>> pharmacies;
  const _PharmacyScreenWithCustomDrag({required this.pharmacies});

  @override
  State<_PharmacyScreenWithCustomDrag> createState() => _PharmacyScreenWithCustomDragState();
}

class _PharmacyScreenWithCustomDragState extends State<_PharmacyScreenWithCustomDrag> {
  double sheetTopRatio = 0.45;
  double minRatio = 0.0;
  double maxRatio = 1.0;
  double dragStartDy = 0;
  double dragStartRatio = 0;

  Position? _currentPosition;
  bool _isLoadingData = true; // 위치 및 약국 정보 로딩 상태 통합
  String? _errorMessage;
  List<Map<String, dynamic>> _fetchedPharmacies = []; // 타입 변경: String -> dynamic

  NaverMapController? _mapController;

  // 카카오 로컬 API 키
  static const String _kakaoRestApiKey = 'a0c056f50bd90071dffbaf29d11d54bf';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
      _fetchedPharmacies = [];
    });
    // _updateMapElements(); // 초기화 시점에서는 아직 데이터가 없을 수 있음
    await _determinePosition();
    // _determinePosition 내에서 _currentPosition이 설정된 후 _fetchPharmacies를 호출합니다.
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = '위치 서비스가 비활성화되어 있습니다. 활성화해주세요.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoadingData = false;
          _errorMessage = '위치 권한이 거부되었습니다.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = '위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요.';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        // _isLoadingData는 약국 정보 로딩까지 true 유지
        _errorMessage = null;
      });
      print("Current position: ${_currentPosition}");
      // _moveCameraToCurrentPosition(); // -> _updateMapElements로 대체되어 _fetchPharmacies 성공 후 호출
      if (_currentPosition != null) {
        await _fetchPharmacies(_currentPosition!.latitude, _currentPosition!.longitude);
      }
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = '현재 위치를 가져오는 데 실패했습니다: $e';
      });
    }
  }

  Future<void> _fetchPharmacies(double latitude, double longitude) async {
    // 검색 반경 (미터 단위, 예: 2km)
    const int radius = 2000; 
    final String apiUrl = 
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=약국&y=${latitude}&x=${longitude}&radius=${radius}';
    
    print("Fetching pharmacies from Kakao API: $apiUrl");

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'KakaoAK $_kakaoRestApiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // print("Kakao API Response: $data"); 
        if (data['documents'] != null) {
          final List documents = data['documents'];
          List<Map<String, dynamic>> pharmacies = documents.map((doc) {
            String name = doc['place_name'] ?? '이름 정보 없음';
            String address = doc['road_address_name'] ?? doc['address_name'] ?? '주소 정보 없음';
            String distanceStr = doc['distance']?.toString() ?? ''; 
            double distanceMeters = double.infinity;

            String kakaoLat = doc['y']; // 카카오 응답: y가 위도
            String kakaoLng = doc['x']; // 카카오 응답: x가 경도
            double? pharmacyLatitude;
            double? pharmacyLongitude;

            try {
              if (kakaoLat != null && kakaoLat.isNotEmpty) pharmacyLatitude = double.parse(kakaoLat);
              if (kakaoLng != null && kakaoLng.isNotEmpty) pharmacyLongitude = double.parse(kakaoLng);
            } catch (e) {
              print("Error parsing pharmacy coordinates from Kakao API: lat=$kakaoLat, lng=$kakaoLng, error=$e");
            }

            if (distanceStr.isNotEmpty) {
              try {
                distanceMeters = double.parse(distanceStr);
              } catch (e) {
                print("Error parsing distance from Kakao API: $distanceStr, error: $e");
              }
            }

            return {
              'name': name,
              'distance': distanceMeters == double.infinity 
                  ? '거리 정보 없음' 
                  : (distanceMeters < 1000 
                      ? '${distanceMeters.round()}m' 
                      : '${(distanceMeters/1000).toStringAsFixed(1)}km'),
              'address': address,
              'open': '영업 정보 없음', 
              '_distanceMeters': distanceMeters.toString(), 
              'latitude': pharmacyLatitude, // 약국 위도 추가
              'longitude': pharmacyLongitude, // 약국 경도 추가
              'id': doc['id'] ?? 'no-id-${DateTime.now().millisecondsSinceEpoch}' // 마커 ID용, 없으면 임시 생성
            };
          }).toList();

          // 거리 기준으로 정렬 (가까운 순)
          pharmacies.sort((a, b) {
            final distAStr = a['_distanceMeters'];
            final distBStr = b['_distanceMeters'];

            if (distAStr == null || distAStr.isEmpty || distAStr == 'Infinity') return 1;
            if (distBStr == null || distBStr.isEmpty || distBStr == 'Infinity') return -1;
            
            try {
                final distA = double.parse(distAStr);
                final distB = double.parse(distBStr);
                return distA.compareTo(distB);
            } catch (e) {
                print("Error parsing distance for sorting: $e");
                return 0;
            }
          });

          setState(() {
            _fetchedPharmacies = pharmacies;
            _isLoadingData = false; 
            _errorMessage = pharmacies.isEmpty ? '주변에 약국 정보가 없습니다 (반경: ${radius/1000}km)' : null;
          });
          _updateMapElements(); // 약국 정보 로딩 및 상태 업데이트 후 지도 요소 업데이트
        } else {
          setState(() {
            _isLoadingData = false;
            _errorMessage = '주변에 약국 정보가 없습니다 (반경: ${radius/1000}km)'; 
            _fetchedPharmacies = []; 
          });
        }
      } else {
        print("Kakao API Error: ${response.statusCode}, Body: ${response.body}");
        setState(() {
          _isLoadingData = false;
          _errorMessage = '약국 정보를 가져오는 데 실패했습니다: ${response.statusCode}';
        });
      }
    } catch (e) {
      print("Fetch pharmacies error (Kakao API): $e");
      setState(() {
        _isLoadingData = false;
        _errorMessage = '약국 정보 검색 중 오류가 발생했습니다.';
      });
    }
  }

  void _onMapReady(NaverMapController controller) {
    _mapController = controller;
    print("NaverMap is ready!");
    _updateMapElements(); // 맵 준비 완료 후에도 지도 요소 업데이트 시도
  }

  void _updateMapElements() {
    if (_mapController == null) return; // 맵 컨트롤러가 준비되지 않았으면 아무것도 안 함

    _mapController!.clearOverlays(type: NOverlayType.marker); // 기존 마커 모두 삭제

    Set<NMarker> markers = {};

    // 1. 현재 위치 마커 추가 (SDK 기본 마커 사용)
    if (_currentPosition != null) {
      final currentPosMarker = NMarker(
        id: 'current_location',
        position: NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        // icon 및 anchor 설정 제거 -> SDK 기본 마커 사용
      );
      markers.add(currentPosMarker);
      // 현재 위치로 카메라 이동 (약국이 많을 경우 줌 레벨 조정 필요할 수 있음)
      _mapController!.updateCamera(NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 15
      ));
    }

    // 2. 약국 위치 마커 추가
    for (var pharmacy in _fetchedPharmacies) {
      final lat = pharmacy['latitude'] as double?;
      final lng = pharmacy['longitude'] as double?;
      final id = pharmacy['id'] as String;
      final name = pharmacy['name'] as String;

      if (lat != null && lng != null) {
        final pharmacyMarker = NMarker(
          id: 'pharmacy_$id',
          position: NLatLng(lat, lng), 
          caption: NOverlayCaption(text: name, minZoom: 12) // icon 설정 없음 (기본 마커 사용)
        );
        markers.add(pharmacyMarker);
      }
    }

    if (markers.isNotEmpty) {
      _mapController!.addOverlayAll(markers);
      print("Map elements updated with ${markers.length} markers.");
    } else {
      print("No markers to update.");
    }
  }

  void _showCallDialog(BuildContext context, String pharmacyName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    minLeadingWidth: 48,
                    leading: Icon(Icons.phone, size: 28, color: Colors.black87),
                    title: Text(
                      '전화상담요청',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    minLeadingWidth: 48,
                    leading: Icon(Icons.phone, size: 28, color: Colors.black87),
                    title: Text(
                      '02-123-4567',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                    ),
                    subtitle: Text(
                      '전화걸기',
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final height = MediaQuery.of(context).size.height;
    final sheetTop = height * sheetTopRatio;

    return Stack(
      children: [
        // 지도 (항상 배경)
        Positioned.fill(
          child: NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: _currentPosition != null
                    ? NLatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : NLatLng(37.5666102, 126.9783881), // 서울 시청 기본 위치
                zoom: 15,
              ),
              locationButtonEnable: true, 
              // 기본 제스처 확대/축소는 활성화 상태로 둡니다.
              // 만약 UI 버튼으로만 제어하고 싶다면 다음 옵션들을 false로 설정할 수 있습니다.
              // scrollGesturesEnable: true,
              // zoomGesturesEnable: true, 
              // tiltGesturesEnable: true,
              // rotateGesturesEnable: true,
              // stopGesturesEnable: true,
              // liteModeEnable: false,
            ),
            onMapReady: _onMapReady,
          ),
        ),
        
        // 확대/축소 버튼 UI
        Positioned(
          bottom: sheetTop + 20, // 하단 시트 바로 위에 위치 (시트가 완전히 올라왔을 때 기준)
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FloatingActionButton.small(
                heroTag: 'zoomInButton', // heroTag를 고유하게 설정
                backgroundColor: Colors.white.withOpacity(0.9),
                elevation: 2,
                child: Icon(Icons.add, color: Colors.black54),
                onPressed: () {
                  _mapController?.updateCamera(NCameraUpdate.zoomIn());
                },
              ),
              SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoomOutButton', // heroTag를 고유하게 설정
                backgroundColor: Colors.white.withOpacity(0.9),
                elevation: 2,
                child: Icon(Icons.remove, color: Colors.black54),
                onPressed: () {
                  _mapController?.updateCamera(NCameraUpdate.zoomOut());
                },
              ),
            ],
          ),
        ),

        // 리스트 시트 (기존 UI 유지)
        AnimatedPositioned(
          duration: Duration(milliseconds: 200),
          curve: Curves.ease,
          top: sheetTop,
          left: 0,
          right: 0,
          height: height - sheetTop, 
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            elevation: 8,
            child: Column(
              children: [
                // 드래그 바 (기존 UI 유지)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragStart: (details) {
                    dragStartDy = details.globalPosition.dy;
                    dragStartRatio = sheetTopRatio;
                  },
                  onVerticalDragUpdate: (details) {
                    final dragDy = details.globalPosition.dy - dragStartDy;
                    final newRatio = (dragStartRatio + dragDy / height).clamp(minRatio, maxRatio);
                    setState(() {
                      sheetTopRatio = newRatio;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 36,
                    alignment: Alignment.center,
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                // 리스트 영역 (기존 더미 데이터 사용)
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: true,
                    child: _fetchedPharmacies.isEmpty && !_isLoadingData 
                        ? Center(child: Text(_errorMessage ?? '주변에 약국 정보가 없습니다.')) 
                        : ListView.separated(
                            padding: EdgeInsets.only(top: 0, bottom: 24),
                            itemCount: _fetchedPharmacies.length, // _fetchedPharmacies 사용
                            separatorBuilder: (context, idx) => Divider(thickness: 1, height: 1),
                            itemBuilder: (context, idx) {
                              final p = _fetchedPharmacies[idx]; // _fetchedPharmacies 사용
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PharmacyDetailScreen(pharmacy: p),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              p['name']!,
                                              style: TextStyle(
                                                color: Colors.blue[800],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 26,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              '${p['distance']!}   ${p['address']!}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 20,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '영업 중 ',
                                                    style: TextStyle(fontSize: 20),
                                                  ),
                                                  TextSpan(
                                                    text: p['open']!,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 22,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(right: 8.0, bottom: 4.0),
                                        child: IconButton(
                                          icon: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Color(0xFFFFD954), width: 3),
                                            ),
                                            child: Center(
                                              child: Icon(Icons.phone, color: Color(0xFFFFD954), size: 40),
                                            ),
                                          ),
                                          iconSize: 60,
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minWidth: 60, minHeight: 60),
                                          onPressed: () => _showCallDialog(context, p['name']!),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PharmacyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pharmacy;
  const PharmacyDetailScreen({required this.pharmacy, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 항상 임시 이미지 사용
    final String imageAsset = 'https://via.placeholder.com/400x200.png?text=Pharmacy';
    final double imageHeight = MediaQuery.of(context).size.height * 0.5;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          pharmacy['name'] ?? '약국 상세',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 이미지 박스
          Container(
            height: imageHeight,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              image: DecorationImage(
                image: NetworkImage(imageAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 약국 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      (pharmacy['distance'] ?? '') + ' ',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black),
                    ),
                    Expanded(
                      child: Text(
                        pharmacy['address'] ?? '',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text('영업 중 ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(
                      pharmacy['open'] ?? '',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 버튼 2개
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFF3D1),
                        foregroundColor: Colors.black,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      onPressed: () {
                        // 전화걸기 기능 연결 예정
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, size: 54, color: Colors.black),
                          SizedBox(height: 14),
                          Text('전화걸기', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFF3D1),
                        foregroundColor: Colors.black,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                '정기구독 신청',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              content: Text(
                                '${pharmacy['name']}에서 정기구독을 신청하시겠습니까?',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    '취소',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('정기구독 신청이 완료되었습니다.'),
                                        duration: Duration(seconds: 2),
                                        backgroundColor: Color(0xFFFFD954),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    '신청하기',
                                    style: TextStyle(
                                      color: Color(0xFFFFB300),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services, size: 54, color: Colors.black),
                          SizedBox(height: 14),
                          Text('정기구독', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 