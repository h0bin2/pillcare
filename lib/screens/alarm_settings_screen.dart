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
        title: const Text('알림 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
        backgroundColor: Color(0xFFFFD954),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // 로그인 상태에 따라 노란색 로그인 버튼 노출
          Builder(
            builder: (context) {
              // AuthService 등에서 로그인 상태를 받아와야 하지만, 예시로 항상 노출
              // 실제로는 Provider, context.select 등으로 로그인 상태 체크 필요
              return Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFFFFD954),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // 로그인 페이지로 이동
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                ),
              );
            },
          ),
        ],
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