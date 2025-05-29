import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_settings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettingsProvider>(context);
    final isDarkMode = appSettings.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final calendarHeaderColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final calendarDayColor = isDarkMode ? Colors.grey[300] : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: calendarHeaderColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '복약 기록',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(20),
                      selectedColor: textColor,
                      fillColor: Color(0xFFFFD954),
                      color: textColor,
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
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('월', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('주', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                        ),
                      ],
                    ),
                  ],
                ),
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2024, 12, 31),
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
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFFFFD954),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Color(0xFFFFD954).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: TextStyle(color: calendarDayColor),
                    weekendTextStyle: TextStyle(color: calendarDayColor),
                    outsideTextStyle: TextStyle(color: calendarDayColor.withOpacity(0.5)),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
                    rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
                  ),
                ),
              ],
            ),
          ),
          // ... existing code ...
        ],
      ),
    );
  }
} 