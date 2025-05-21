import 'package:flutter/material.dart';

class AlarmSettingsScreen extends StatelessWidget {
  const AlarmSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('알림 관리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
        backgroundColor: Color(0xFFFFD954),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 실제 알림 데이터 연동 전, 예시 더미 데이터
          ListTile(
            leading: Icon(Icons.alarm, color: Color(0xFFFFB300), size: 32),
            title: Text('아침 약 복용', style: TextStyle(fontSize: 22, color: Colors.black)),
            subtitle: Text('매일 오전 8:00', style: TextStyle(color: Colors.black87)),
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeColor: Color(0xFFFFB300),
            ),
            tileColor: Color(0xFFFFF8E1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          ListTile(
            leading: Icon(Icons.alarm, color: Color(0xFFFFB300), size: 32),
            title: Text('점심 약 복용', style: TextStyle(fontSize: 22, color: Colors.black)),
            subtitle: Text('매일 오후 1:00', style: TextStyle(color: Colors.black87)),
            trailing: Switch(
              value: false,
              onChanged: (v) {},
              activeColor: Color(0xFFFFB300),
            ),
            tileColor: Color(0xFFFFF8E1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          ListTile(
            leading: Icon(Icons.alarm, color: Color(0xFFFFB300), size: 32),
            title: Text('저녁 약 복용', style: TextStyle(fontSize: 22, color: Colors.black)),
            subtitle: Text('매일 오후 7:00', style: TextStyle(color: Colors.black87)),
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeColor: Color(0xFFFFB300),
            ),
            tileColor: Color(0xFFFFF8E1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          ListTile(
            leading: Icon(Icons.alarm, color: Color(0xFFFFB300), size: 32),
            title: Text('오메가 3 약 복용', style: TextStyle(fontSize: 22, color: Colors.black)),
            subtitle: Text('매일 오후 9:00', style: TextStyle(color: Colors.black87)),
            trailing: Switch(
              value: false,
              onChanged: (v) {},
              activeColor: Color(0xFFFFB300),
            ),
            tileColor: Color(0xFFFFF8E1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          // 실제 알림 데이터 연동 시 이 부분을 동적으로 생성
        ],
      ),
    );
  }
} 