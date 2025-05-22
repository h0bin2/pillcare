import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'home_screen.dart';
import 'camera_screen.dart';
import 'medicine_info_screen.dart';
import 'pharmacy_screen.dart';
import 'settings_screen.dart';

import '../services/auth_service.dart';
import '../models/user_info.dart';
import '../models/consultation_info.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late String _currentDate;
  Timer? _timer;
  late Future<UserInfo?> _userInfoFuture;
  Future<List<ConsultationInfo>>? _consultationHistoryFuture;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw '전화를 걸 수 없습니다: $phoneNumber';
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _updateDate();
    // 매일 자정에 날짜 업데이트
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (now.hour == 0 && now.minute == 0) {
        _updateDate();
      }
    });

    _userInfoFuture = _loadUserInfo();
    _userInfoFuture.then((userInfo) {
      if (userInfo != null && mounted) {
        if (userInfo.id != null) {
          setState(() {
            _consultationHistoryFuture = AuthService.getConsultationHistory(userInfo.id!);
          });
        } else {
          printError("initState: UserInfo에 id 필드가 없습니다. 상담 내역을 로드할 수 없습니다.");
          setState(() {
            _consultationHistoryFuture = Future.value([]);
          });
        }
      } else if (mounted) {
        printError("initState: 사용자 정보를 가져오지 못했습니다.");
        setState(() {
          _consultationHistoryFuture = Future.value([]);
        });
      }
    }).catchError((error) {
      if (mounted) {
        printError("initState: 사용자 정보 로드 중 오류: $error");
        setState(() {
          _consultationHistoryFuture = Future.error(error);
        });
      }
    });
  }

  Future<UserInfo?> _loadUserInfo() async {
    try {
      final userInfoMap = await AuthService.getCurrentUserInfo();
      if (userInfoMap != null) {
        return UserInfo.fromJson(userInfoMap);
      }
      return null;
    } catch (e) {
      print("Error in _loadUserInfo: $e");
      return null;
    }
  }

  void printError(String message) {
    if (kDebugMode) {
      print('\x1B[31m$message\x1B[0m');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateDate() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy. MM. dd');
    final weekDay = _getWeekDay(now.weekday);
    setState(() {
      _currentDate = '${formatter.format(now)} ($weekDay)';
    });
  }

  String _getWeekDay(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  // 전화 옵션 모달 함수 추가
  void _showPhoneOptions(BuildContext context, String phoneNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 전화상담요청 버튼
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  minimumSize: const Size.fromHeight(48),
                  alignment: Alignment.centerLeft,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.phone, color: Colors.black, size: 32),
                label: Text(
                  '전화상담요청',
                  style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
                ),
                onPressed: () {
                  // TODO: 전화상담요청 로직
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              // 전화걸기 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  minimumSize: const Size.fromHeight(48),
                  alignment: Alignment.centerLeft,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _makePhoneCall(phoneNumber);
                },
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.black, size: 32),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(phoneNumber, style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                        Text('전화걸기', style: TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'NotoSansKR')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 180,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentDate,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: constraints.maxHeight * 0.1,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.05),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              FutureBuilder<UserInfo?>(
                                future: _userInfoFuture,
                                builder: (context, snapshot) {
                                  Widget nameWidget;
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    nameWidget = SizedBox(
                                        width: constraints.maxHeight * 0.3,
                                        height: constraints.maxHeight * 0.3,
                                        child: CircularProgressIndicator(strokeWidth: 2));
                                  } else if (snapshot.hasError) {
                                    printError("Error loading user info in FutureBuilder: \\${snapshot.error}");
                                    nameWidget = Text('사용자 로딩 오류', style: TextStyle(fontSize: constraints.maxHeight * 0.3, color: Colors.red, fontFamily: 'NotoSansKR'));
                                  } else if (snapshot.hasData && snapshot.data != null) {
                                    final userInfo = snapshot.data!;
                                    nameWidget = Text(
                                      userInfo.nickname ?? '최순자',
                                      style: TextStyle(
                                        fontSize: constraints.maxHeight * 0.3,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF000080),
                                        fontFamily: 'NotoSansKR',
                                      ),
                                    );
                                  } else {
                                    nameWidget = Text('방문자', style: TextStyle(fontSize: constraints.maxHeight * 0.3, fontWeight: FontWeight.w900, color: Color(0xFF000080), fontFamily: 'NotoSansKR'));
                                  }
                                  
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          nameWidget,
                                          Text(
                                            '님',
                                            style: TextStyle(
                                              fontSize: constraints.maxHeight * 0.2,
                                              color: Colors.black,
                                              fontFamily: 'NotoSansKR',
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: constraints.maxHeight * 0.05),
                                      Text(
                                        '약 드셨나요?',
                                        style: TextStyle(
                                          fontSize: constraints.maxHeight * 0.2,
                                          color: Colors.black,
                                          fontFamily: 'NotoSansKR',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Spacer(),
                              Container(
                                width: constraints.maxHeight * 0.8,
                                height: constraints.maxHeight * 0.8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '추천',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicineInfoScreen(
                        name: '오메가-3',
                        imagePath: 'assets/omega3.png',
                        effects: [
                          '신체 염증을 줄이고 혈액 건강에 도움이 됩니다.',
                          '혈중 중성지방 감소',
                          '심혈관 건강 개선',
                          '눈 건강 유지',
                        ],
                        usage: [
                          '성인: 1일 1~2회, 1회 1캡슐 식후 복용',
                          '어린이: 의사와 상담 후 복용',
                        ],
                        cautions: [
                          '과다 복용 시 출혈 위험 증가',
                          '임산부, 수유부는 복용 전 의사와 상담',
                          '혈액 응고 억제제와 병용 시 주의',
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFD954),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.medication,
                              color: Colors.black54,
                              size: 40,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '오메가-3',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            '신체 염증을 줄이고 혈액 건강에 도움이 됩니다.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              height: 1.4,
                              fontFamily: 'NotoSansKR',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최근 상담 내역',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              FutureBuilder<List<ConsultationInfo>>(
                future: _consultationHistoryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    printError("Error loading consultation history: \\${snapshot.error}");
                    return Center(child: Text('상담 내역을 불러오는 중 오류가 발생했습니다.', style: TextStyle(color: Colors.red, fontFamily: 'NotoSansKR')));
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final consultations = snapshot.data!;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade500),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: consultations.length,
                        itemBuilder: (context, index) {
                          final consultation = consultations[index];
                          return Container(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            consultation.pharmacyName,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              fontFamily: 'NotoSansKR',
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            consultation.formattedCreatedAt,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              fontFamily: 'NotoSansKR',
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        consultation.history,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                          fontFamily: 'NotoSansKR',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade300,
                          indent: 20,
                          endIndent: 20,
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 70, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '최근 상담 내역이 없습니다.',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'NotoSansKR'),
                        ),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Material(
              color: Color(0xFFFFD954),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 105,
                  height: 90,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.black,
                        size: 42,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '기록',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansKR',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: Color(0xFFFFD954),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 105,
                  height: 90,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.black,
                        size: 42,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '카메라',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansKR',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: Color(0xFFFFD954),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PharmacyScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 105,
                  height: 90,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.black,
                        size: 42,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '약국',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansKR',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.yellow[700],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 40,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
      ],
    );
  }
}
