// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../services/record_service.dart';
import 'package:intl/intl.dart'; // isSameDay 사용 및 날짜 포맷 위해 필요

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  bool _isLoading = true;
  List<Map<String, dynamic>>? _userRecords;
  String? _fetchError;
  int _currentPageIndex = 0; // PageView 현재 페이지 인덱스

  // 더미 약 데이터는 이제 사용 안 함
  // final List<Map<String, dynamic>> dummyMeds = [ ... ];

  @override
  void initState() {
    super.initState();
    // 초기 선택일 설정 (선택 사항, 오늘 날짜 기준으로 데이터를 먼저 보여줄 수 있음)
    // _selectedDay = _focusedDay;
    _fetchUserRecords();
  }

  Future<void> _fetchUserRecords() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _fetchError = null;
      _currentPageIndex = 0; // 데이터 다시 불러올 때 인덱스 초기화
    });

    try {
      final records = await RecordService.getRecords();
      if (!mounted) return;

      if (records != null) {
        setState(() {
          _userRecords = records;
          if (kDebugMode) {
            print('[HomeScreen] Successfully fetched ${_userRecords!.length} records.');
          }
        });
      } else {
        setState(() {
          _fetchError = '레코드 정보를 가져오는데 실패했습니다.';
          if (kDebugMode) {
            print('[HomeScreen] Failed to fetch records (null returned from service).');
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchError = '오류 발생: ${e.toString()}';
        if (kDebugMode) {
          print('[HomeScreen] Error fetching records: $e');
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // <<< 선택된 날짜에 해당하는 레코드 필터링 함수 >>>
  List<Map<String, dynamic>> _getFilteredRecordsForSelectedDay() {
    if (_userRecords == null || _selectedDay == null) {
      return [];
    }

    return _userRecords!.where((record) {
      try {
        if (record['created_at'] != null && record['created_at'] is String) {
          final String createdAtString = record['created_at'] as String;
          // 백엔드가 +09:00 와 같은 오프셋을 포함한 ISO 문자열을 반환한다고 가정
          // 예: "2023-10-28T14:30:00+09:00"
          final DateTime recordDateTime = DateTime.parse(createdAtString);
          final kstDateTime = recordDateTime.toLocal();
          final displayString = DateFormat('HH:mm').format(kstDateTime);
          // print('created_at: $createdAtString, parsed: $recordDateTime, local: $kstDateTime');
          return isSameDay(kstDateTime, _selectedDay!);
        } else {
          if(kDebugMode) print('[HomeScreen] Invalid or missing created_at for record: ${record['id']}');
          return false;
        }
      } catch (e) {
        if (kDebugMode) print('[HomeScreen] Error parsing or comparing created_at for record ${record['id']}: $e. Value: ${record['created_at']}');
        return false;
      }
    }).toList();
  }

  // _getGroupedPillsForSelectedDay() 함수는 각 레코드별로 약물을 보여주므로 더 이상 이 형태로 사용되지 않음
  // Map<String, Map<String, dynamic>> _getGroupedPillsForSelectedDay() { ... }

  // _HomeScreenState 클래스 내부에 추가
  bool _dayHasRecords(DateTime day) {
    if (_userRecords == null) return false;
    return _userRecords!.any((record) {
      if (record['created_at'] != null && record['created_at'] is String) {
        try {
          final createdAt = DateTime.parse(record['created_at']);
          return isSameDay(createdAt, day);
        } catch (e) {
          return false;
        }
      }
      return false;
    });
  }

  // _HomeScreenState 클래스 내부에 추가
  String _getFormattedTime(String? createdAtIsoString) {
    if (createdAtIsoString == null || createdAtIsoString.isEmpty) {
      return '--:--';
    }
    try {
      // createdAtIsoString은 이미 KST이며, 오프셋 정보(+09:00)를 포함하고 있음
      final DateTime dateTimeKST = DateTime.parse(createdAtIsoString).toLocal();
      return DateFormat('HH:mm').format(dateTimeKST); // 'HH:mm' 형식으로 시간만 표시
    } catch (e) {
      if (kDebugMode) {
        print('[HomeScreen] Error formatting time: $e for string $createdAtIsoString');
      }
      return '--:--';
    }
  }

  // --- 각 기록(record_id)별 페이지를 만드는 헬퍼 함수 ---
  Widget _buildRecordItemPage(Map<String, dynamic> recordData) {
    final String? imagePath = recordData['original_image_path'];
    final List<dynamic> pillDetails = recordData['details'] ?? [];

    String imageUrl = 'https://via.placeholder.com/400x200.png?text=No+Image';
    bool canLoadImage = false;
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http')) {
        imageUrl = imagePath;
      } else if (!imagePath.startsWith('/')) {
        imageUrl = 'http://192.168.45.208:5555/$imagePath';
      } else {
        imageUrl = 'http://192.168.45.208:5555$imagePath';
      }
      canLoadImage = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF888888)),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF5F5F5),
            ),
            child: Center(
              child: canLoadImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.fill,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        if (kDebugMode) print('[HomeScreen-_buildRecordItemPage] Image load error: $error for URL: $imageUrl');
                        return const Center(child: Text('이미지 로딩 실패', style: TextStyle(color: Colors.red)));
                      },
                    )
                  : const Text('이미지 없음', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 20),
          if (pillDetails.isNotEmpty)
            ...pillDetails.map((detail) {
              if (detail is! Map<String, dynamic>) return const SizedBox.shrink();
              final String pillName = detail['pill_name'] ?? '이름 모름';
              final int count = detail['pill_count'] ?? 0;
              final String effect = detail['effect'] ?? '효능 정보 없음';
              // 상세/삭제 다이얼로그 함수
              void _showPillActionDialog() {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(
                        pillName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black, fontFamily: 'NotoSansKR'),
                      ),
                      content: Text(
                        effect,
                        style: const TextStyle(fontSize: 18, color: Colors.black87, fontFamily: 'NotoSansKR'),
                      ),
                      actions: [
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF3D1),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/medicine_info',
                              arguments: detail,
                            );
                          },
                          child: const Text('상세보기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'NotoSansKR')),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD954),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            final recordId = recordData['id'];
                            final pillId = detail['pill_id'];
                            if (recordId != null && pillId != null) {
                              final success = await RecordService.deletePill(recordId: recordId, pillId: pillId);
                              if (success) {
                                setState(() {
                                  pillDetails.remove(detail);
                                });
                                // pillDetails가 0개가 되면 record도 삭제
                                if (pillDetails.isEmpty) {
                                  final recordDeleteSuccess = await RecordService.deleteRecord(recordId);
                                  if (recordDeleteSuccess) {
                                    setState(() {
                                      _userRecords?.remove(recordData);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('마지막 약이 삭제되어 기록도 함께 삭제되었습니다.'), backgroundColor: Color(0xFFFFD954)),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('약 정보가 삭제되었습니다.'), backgroundColor: Color(0xFFFFD954)),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('약 정보 삭제에 실패했습니다.'), backgroundColor: Colors.red),
                                );
                              }

                            }
                          },
                          child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'NotoSansKR')),
                        ),
                      ],
                    );
                  },
                );
              }
              return GestureDetector(
                onTap: _showPillActionDialog,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFF5F5F5),
                          child: const Icon(Icons.medication, color: Color(0xFFFFB300), size: 40),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$pillName ($count개)',
                              style: const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'NotoSansKR'),
                            ),
                            const SizedBox(height: 4),
                            Text('• $effect', style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.alarm, color: Color(0xFFFFB300), size: 32),
                        onPressed: () {
                          _showAlarmPicker(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList()
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('이 기록에는 등록된 약 정보가 없습니다.', style: TextStyle(fontFamily: 'NotoSansKR'))),
            ),
        ],
      ),
    );
  }

  // --- 페이지 인디케이터 위젯 ---
  Widget _buildPageIndicator(int itemCount) {
    if (itemCount <= 1) return const SizedBox.shrink(); // 페이지가 하나 이하면 인디케이터 숨김

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPageIndex == index
                ? Theme.of(context).primaryColor // 활성 페이지 색상 (기본 테마색 사용)
                : Colors.grey.withOpacity(0.5),   // 비활성 페이지 색상
          ),
        );
      }),
    );
  }

  void _showAlarmPicker(BuildContext context) {
    final List<String> ampm = ['오전', '오후'];
    final List<int> hours = List.generate(12, (i) => i + 1);
    final List<int> minutes = List.generate(12, (i) => i * 5);
    int selectedAmpm = 0;
    int selectedHour = 7;
    int selectedMinute = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[300],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 오전/오후
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: selectedAmpm),
                      itemExtent: 40,
                      onSelectedItemChanged: (idx) {
                        setState(() => selectedAmpm = idx);
                      },
                      children: ampm.map((e) => Center(
                        child: Text(
                          e,
                          style: TextStyle(
                            fontSize: selectedAmpm == ampm.indexOf(e) ? 24 : 20,
                            fontWeight: selectedAmpm == ampm.indexOf(e) ? FontWeight.bold : FontWeight.normal,
                            color: selectedAmpm == ampm.indexOf(e) ? Colors.black : Colors.grey,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  // 시
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: selectedHour-1),
                      itemExtent: 40,
                      onSelectedItemChanged: (idx) {
                        setState(() => selectedHour = hours[idx]);
                      },
                      children: hours.map((h) => Center(
                        child: Text(
                          '$h',
                          style: TextStyle(
                            fontSize: selectedHour == h ? 32 : 24,
                            fontWeight: selectedHour == h ? FontWeight.bold : FontWeight.normal,
                            color: selectedHour == h ? Colors.black : Colors.grey,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  // :
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(':', style: TextStyle(fontSize: 32, color: Colors.grey[400], fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                  ),
                  // 분
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: selectedMinute~/5),
                      itemExtent: 40,
                      onSelectedItemChanged: (idx) {
                        setState(() => selectedMinute = minutes[idx]);
                      },
                      children: minutes.map((m) => Center(
                        child: Text(
                          m.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: selectedMinute == m ? 32 : 24,
                            fontWeight: selectedMinute == m ? FontWeight.bold : FontWeight.normal,
                            color: selectedMinute == m ? Colors.black : Colors.grey,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _getFilteredRecordsForSelectedDay();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(Icons.arrow_back_ios_new, size: 36, color: Colors.black),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. 달력 섹션 (커스텀 헤더 포함, 상단 고정) - 기존 코드 유지
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 커스텀 헤더: 월/연도 + 월/주 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                          onPressed: () {
                            setState(() {
                              _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month - 1,
                                1,
                              );
                              _currentPageIndex = 0; // 월 변경 시 인덱스 초기화
                            });
                          },
                        ),
                        Text(
                          '${_focusedDay.year}년 ${_focusedDay.month}월',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 24),
                          onPressed: () {
                            setState(() {
                              _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month + 1,
                                1,
                              );
                              _currentPageIndex = 0; // 월 변경 시 인덱스 초기화
                            });
                          },
                        ),
                      ],
                    ),
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(20),
                      selectedColor: Colors.black,
                      fillColor: Color(0xFFFFD954), // 진한 노란색
                      color: Colors.black,
                      isSelected: [
                        _calendarFormat == CalendarFormat.month,
                        _calendarFormat == CalendarFormat.week,
                      ],
                      onPressed: (index) {
                        setState(() {
                          if (index == 0) {
                            _calendarFormat = CalendarFormat.month;
                          } else if (index == 1) {
                            _calendarFormat = CalendarFormat.week;
                          }
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('월', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('주', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                // TableCalendar
                Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text('월', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                      Text('화', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                      Text('수', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                      Text('목', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                      Text('금', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                      Text('토', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                      Text('일', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                TableCalendar(
                  headerVisible: false, 
                  daysOfWeekVisible: false, 
                  locale: 'ko_KR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay; 
                      _currentPageIndex = 0; 
                    });
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Color(0xFFFFD954), 
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      BoxDecoration? decoration;
                      TextStyle textStyle = const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black);
                      bool hasRecords = _dayHasRecords(day);
                      if (!isSameDay(day, _selectedDay) && !isSameDay(day, DateTime.now()) && hasRecords) {
                        decoration = BoxDecoration(color: Colors.green.withOpacity(0.3), shape: BoxShape.circle);
                      }
                      return Center(child: Container(decoration: decoration, padding: const EdgeInsets.all(6), child: Text('${day.day}', style: textStyle)));
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(6),
                          child: Text('${day.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      BoxDecoration decoration = const BoxDecoration(color: Color(0xFFFFD954), shape: BoxShape.circle);
                      bool hasRecords = _dayHasRecords(day);
                      if (isSameDay(day, DateTime.now()) && !isSameDay(day, _selectedDay) && hasRecords) {
                        decoration = BoxDecoration(color: Colors.green.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFD954), width: 2));
                      }
                      return Center(child: Container(decoration: decoration, padding: const EdgeInsets.all(6), child: Text('${day.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black))));
                    },
                  ),
                ),
              ],
            ),
          ),
          // 2. 페이지 인디케이터 (달력 아래)
          if (filteredRecords.isNotEmpty)
            _buildPageIndicator(filteredRecords.length),

          // 3. 현재 슬라이드의 KST 시간 표시 (인디케이터 아래)
          if (filteredRecords.isNotEmpty && _currentPageIndex < filteredRecords.length && filteredRecords[_currentPageIndex]['created_at'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '${_getFormattedTime(filteredRecords[_currentPageIndex]['created_at'])}',
                style: const TextStyle(fontSize: 16.0, color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ),
          // 4. PageView (슬라이드 영역)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _fetchError != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('오류: $_fetchError', textAlign: TextAlign.center),
                      ))
                    : filteredRecords.isEmpty
                        ? Center(child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('선택된 날짜에 기록된 정보가 없습니다.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ))
                        : PageView.builder(
                            itemCount: filteredRecords.length,
                            controller: PageController(initialPage: _currentPageIndex),
                            onPageChanged: (index) {
                              setState(() {
                                _currentPageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final record = filteredRecords[index];
                              return _buildRecordItemPage(record);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}