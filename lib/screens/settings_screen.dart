import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_info.dart';
import 'alarm_settings_screen.dart';
import 'export_medication_screen.dart';
import 'font_theme_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 프로필 영역 (메인 페이지와 연동)
          FutureBuilder<UserInfo?>(
            future: AuthService.getCurrentUserInfo().then((map) => map != null ? UserInfo.fromJson(map) : null),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  child: Text('프로필 정보를 불러오지 못했습니다.', style: TextStyle(color: Colors.red)),
                );
              } else {
                final userInfo = snapshot.data;
                final String name = userInfo?.nickname ?? '방문자';
                final String nickname = userInfo?.nickname ?? '-';
                final String? profileImage = null; // 항상 null로 두고 기본 이미지 사용
                return Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: AssetImage('assets/profile_placeholder.png'),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('닉네임: $nickname', style: TextStyle(fontSize: 20, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // 정보 수정 페이지로 이동 또는 다이얼로그
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFD954),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text('정보수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          const Divider(height: 1, thickness: 1),
          // 설정 리스트
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.notifications, color: Colors.black, size: 32),
                  title: Text('알림 설정', style: TextStyle(fontSize: 22)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 24, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AlarmSettingsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.file_download, color: Colors.black, size: 32),
                  title: Text('복약 기록 내보내기', style: TextStyle(fontSize: 22)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 24, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExportMedicationScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.format_size, color: Colors.black, size: 32),
                  title: Text('글씨 크기/다크모드', style: TextStyle(fontSize: 22)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 24, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FontAndThemeSettingsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.contact_support, color: Colors.black, size: 32),
                  title: Text('문의하기', style: TextStyle(fontSize: 22)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 24, color: Colors.grey),
                  onTap: () {
                    // TODO: 문의하기 기능 구현
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red, size: 32),
                  title: Text('로그아웃', style: TextStyle(fontSize: 22, color: Colors.red)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            '로그아웃',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          content: Text(
                            '로그아웃 하시겠습니까?',
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
                              onPressed: () async {
                                Navigator.pop(context);
                                await AuthService.logout();
                                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                              },
                              child: Text(
                                '로그아웃',
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
                ),
                // 추가 설정 항목은 여기에 계속 추가 가능
              ],
            ),
          ),
        ],
      ),
    );
  }
} 