// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'main_screen.dart';
import 'package:flutter/cupertino.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 더미 약 데이터
  final List<Map<String, dynamic>> dummyMeds = [
    {
      'name': '오메가-3',
      'effects': ['심혈관 건강 개선', '눈 건강 유지'],
      'image': 'https://via.placeholder.com/60',
    },
    {
      'name': '다이크로질',
      'effects': ['고혈압 개선', '부종 개선'],
      'image': 'https://via.placeholder.com/60',
    },
  ];

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
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  // :
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(':', style: TextStyle(fontSize: 32, color: Colors.grey[400], fontWeight: FontWeight.bold)),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
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
          // 1. 달력 섹션 (커스텀 헤더 포함, 상단 고정)
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
                  headerVisible: false, // 헤더(포맷 버튼 포함) 숨김
                  daysOfWeekVisible: false, // 기본 요일 라벨 숨김
                  locale: 'ko_KR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Color(0xFFFFD954), // 진한 노란색
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD954),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD954),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
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
          // 2. 이미지 박스 + 약 정보 카드 리스트 (아래만 스크롤)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20),
              children: [
                // 이미지용 테두리 박스
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF888888)),
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFFF5F5F5),
                  ),
                  child: const Center(
                    child: Text(
                      '여기에 사용자가 찍은 약 사진이 들어갑니다',
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  ),
                ),
                // 약 정보 카드 리스트
                ...dummyMeds.map((med) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: Color(0xFFF5F5F5),
                          child: Icon(
                            Icons.medication,
                            color: Color(0xFFFFB300),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med['name'],
                              style: const TextStyle(
                                color: Color(0xFFFFB300),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...med['effects'].map<Widget>((e) => Text(
                              '• $e',
                              style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                            )).toList(),
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
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}