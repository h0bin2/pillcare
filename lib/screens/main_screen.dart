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
import 'notice_screen.dart';
import 'consultation_history_page.dart';
import 'pharmacy_detail_screen.dart';

import '../services/auth_service.dart';
import '../models/user_info.dart';
import '../models/consultation_info.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late String _currentDate;
  Timer? _timer;
  late Future<UserInfo?> _userInfoFuture;
  Future<List<ConsultationInfo>>? _consultationHistoryFuture;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredSuggestions = [];
  List<String> recentSearches = [];

  // 더미 추천 검색어 데이터
  final List<String> suggestions = [
    '타이레놀', '아스피린', '감기약', '두통약', '소화제',
    '지성약국', '소나무한약국', '행복한약국',
    '타이밍', '타이거밤', '타이드',
    '감기', '두통', '소화불량', '복통',
  ];

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

    // 검색어 입력 리스너 추가
    _searchController.addListener(_onSearchChanged);

    _userInfoFuture = _loadUserInfo();
    _userInfoFuture.then((userInfo) {
      if (userInfo != null && mounted) {
        if (userInfo.id != 0) {
          setState(() {
            _consultationHistoryFuture = AuthService.getConsultationHistory(userInfo.id);
          });
        } else {
          printError("initState: UserInfo에 id 필드가 없거나 0입니다. 상담 내역을 로드할 수 없습니다.");
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MainScreen이 다시 보일 때마다 상담 내역 새로 불러오기
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _userInfoFuture = _loadUserInfo();
      _userInfoFuture.then((userInfo) {
        if (userInfo != null && mounted) {
          if (userInfo.id != 0) {
            setState(() {
              _consultationHistoryFuture = AuthService.getConsultationHistory(userInfo.id);
            });
          } else {
            setState(() {
              _consultationHistoryFuture = Future.value([]);
            });
          }
        } else if (mounted) {
          setState(() {
            _consultationHistoryFuture = Future.value([]);
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _consultationHistoryFuture = Future.error(error);
          });
        }
      });
    }
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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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

  void _onSearchChanged() {
    final searchText = _searchController.text.trim().toLowerCase();
    setState(() {
      if (searchText.isEmpty) {
        filteredSuggestions = [];
      } else {
        filteredSuggestions = suggestions
            .where((suggestion) => suggestion.toLowerCase().contains(searchText))
            .toList();
      }
    });
  }

  void _addToRecentSearches(String keyword) {
    setState(() {
      recentSearches.remove(keyword); // 중복 제거
      recentSearches.insert(0, keyword); // 맨 앞에 추가
      if (recentSearches.length > 3) {
        recentSearches = recentSearches.sublist(0, 3);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            // 기존 메인 컨텐츠
            Column(
              children: [
                // 상단 영역
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // 왼쪽 끝: 설정 아이콘
                      IconButton(
                        icon: Icon(Icons.settings, color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingsScreen()),
                          );
                        },
                      ),
                      Expanded(child: SizedBox()),
                      // 오른쪽 끝에서 두 번째: 공지 아이콘
                      IconButton(
                        icon: Icon(Icons.notifications_none, color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NoticeScreen()),
                          );
                        },
                      ),
                      // 오른쪽 끝: 검색 아이콘
                      IconButton(
                        icon: Icon(
                          _isSearchVisible ? Icons.close : Icons.search,
                          color: Colors.black87,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchVisible = !_isSearchVisible;
                            if (!_isSearchVisible) {
                              _searchController.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // 기존 컨텐츠
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상단 날짜 표시
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _currentDate,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSansKR',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
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
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          FutureBuilder<UserInfo?>(
                                            future: _userInfoFuture,
                                            builder: (context, snapshot) {
                                              Widget nameWidget;
                                              String? profileImageUrl;
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                nameWidget = SizedBox(
                                                    width: constraints.maxHeight * 0.3,
                                                    height: constraints.maxHeight * 0.3,
                                                    child: CircularProgressIndicator(strokeWidth: 2));
                                              } else if (snapshot.hasError) {
                                                printError("Error loading user info in FutureBuilder: \\${snapshot.error}");
                                                nameWidget = Text('사용자 로딩 오류', style: TextStyle(fontSize: constraints.maxHeight * 0.3, color: Colors.red, fontFamily: 'NotoSansKR'));
                                              } else if (snapshot.hasData && snapshot.data != null) {
                                                final userInfo = snapshot.data;
                                                nameWidget = Text(
                                                  userInfo?.nickname ?? '최순자',
                                                  style: TextStyle(
                                                    fontSize: constraints.maxHeight * 0.3,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF000080),
                                                    fontFamily: 'NotoSansKR',
                                                  ),
                                                );
                                                profileImageUrl = userInfo?.profileImageUrl;
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
                                          FutureBuilder<UserInfo?>(
                                            future: _userInfoFuture,
                                            builder: (context, snapshot) {
                                              String? profileImageUrl;
                                              if (snapshot.hasData && snapshot.data != null) {
                                                profileImageUrl = snapshot.data?.profileImageUrl;
                                              }
                                              return Container(
                                                width: constraints.maxHeight * 0.8,
                                                height: constraints.maxHeight * 0.8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 6,
                                                  ),
                                                  image: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                                      ? DecorationImage(
                                                          image: NetworkImage(profileImageUrl),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                              );
                                            },
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
                          FutureBuilder<List<dynamic>>(
                            future: AuthService.getMedicineHistory(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }
                              
                              // 약 기록이 없는 경우
                              if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    // 약 정보 등록 페이지로 이동하는 기능 추가 예정
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFD954),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.medication,
                                            color: Colors.black54,
                                            size: 40,
                                          ),
                                        ),
                                        SizedBox(width: 24),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '약 정보 등록',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black,
                                                  fontFamily: 'NotoSansKR',
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                '복용 중인 약을 등록하시면,\n맞춤형 약 추천과 복약 알림을 받아보실 수 있습니다.',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                  height: 1.4,
                                                  fontFamily: 'NotoSansKR',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              // 약 기록이 있는 경우
                              final medicine = snapshot.data != null && snapshot.data!.isNotEmpty ? snapshot.data![0] : null;
                              if (medicine == null) {
                                return SizedBox.shrink();
                              }
                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MedicineInfoScreen(
                                            name: medicine['name'] ?? '약 정보',
                                            imagePath: medicine['imagePath'] ?? 'assets/default_medicine.png',
                                            effects: List<String>.from(medicine['effects'] ?? []),
                                            usage: List<String>.from(medicine['usage'] ?? []),
                                            cautions: List<String>.from(medicine['cautions'] ?? []),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFD954),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.medication,
                                          color: Colors.black54,
                                          size: 40,
                                        ),
                                      ),
                                      SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              medicine['name'] ?? '약 정보',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black,
                                                fontFamily: 'NotoSansKR',
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              medicine['description'] ?? '약 정보를 확인하세요',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                                height: 1.4,
                                                fontFamily: 'NotoSansKR',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConsultationHistoryPage(consultationHistoryFuture: _consultationHistoryFuture),
                                ),
                              );
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
                              ],
                            ),
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
                                      // 약국 정보 매핑
                                      Map<String, Map<String, String>> pharmacyMap = {
                                        '지성약국': {
                                          'name': '지성약국',
                                          'distance': '570m',
                                          'address': '강릉시 범일로 604, 2층',
                                          'open': '08:30~18:00',
                                          'phone': '033-123-4567',
                                        },
                                        '소나무한약국': {
                                          'name': '소나무한약국',
                                          'distance': '0.92km',
                                          'address': '강릉시 경강로 1951',
                                          'open': '08:30~18:00',
                                          'phone': '033-234-5678',
                                        },
                                      };
                                      final pharmacyInfo = pharmacyMap[consultation.pharmacyName] ?? {
                                        'name': consultation.pharmacyName,
                                        'distance': '',
                                        'address': '',
                                        'open': '',
                                        'phone': '',
                                      };
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PharmacyDetailScreen(
                                                pharmacy: pharmacyInfo,
                                                userInfo: null,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
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
                          SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 검색창 오버레이
            if (_isSearchVisible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearchVisible = false;
                      _searchController.clear();
                    });
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.18),
                  ),
                ),
              ),
            if (_isSearchVisible)
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // 검색창
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 24),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                          bottom: (filteredSuggestions.isNotEmpty || (_searchController.text.isEmpty && recentSearches.isNotEmpty)) ? Radius.zero : Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      height: 48,
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[400]),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: '검색어를 입력하세요',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontFamily: 'NotoSansKR',
                                ),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'NotoSansKR',
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  _addToRecentSearches(value.trim());
                                }
                              },
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                              child: Icon(Icons.close, color: Colors.grey[400], size: 20),
                            ),
                        ],
                      ),
                    ),
                    // 추천 검색어 리스트 (입력 시 항상 뜨게)
                    if (_searchController.text.isNotEmpty)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(maxHeight: 300),
                        child: filteredSuggestions.isEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: Text('추천 검색어가 없습니다.', style: TextStyle(fontFamily: 'NotoSansKR', color: Colors.grey))),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredSuggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = filteredSuggestions[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _searchController.text = suggestion;
                                        _searchController.selection = TextSelection.fromPosition(
                                          TextPosition(offset: suggestion.length),
                                        );
                                        _addToRecentSearches(suggestion);
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Text(
                                        suggestion,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'NotoSansKR',
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                    // 최근 검색어 리스트 (입력 전)
                    if (_searchController.text.isEmpty && recentSearches.isNotEmpty)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: recentSearches.length,
                          itemBuilder: (context, index) {
                            final recent = recentSearches[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _searchController.text = recent;
                                    _searchController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: recent.length),
                                    );
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.history, color: Colors.grey[400], size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          recent,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'NotoSansKR',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
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
            FutureBuilder<UserInfo?>(
              future: _userInfoFuture,
              builder: (context, snapshot) {
                return Material(
                  color: Color(0xFFFFD954),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PharmacyScreen(userInfo: snapshot.data),
                        ),
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
                );
              },
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

