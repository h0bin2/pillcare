import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_info.dart';
import 'alarm_settings_screen.dart';
import 'export_medication_screen.dart';
import 'font_theme_settings_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
              child: FutureBuilder<UserInfo?>(
                future: Future.value(UserInfo(
                  id: 1,
                  kakaoId: 'test_kakao_id',
                  nickname: '테스트유저',
                  profileImageUrl: '',
                  // 필요한 필드 추가
                )),
                builder: (context, snapshot) {
                  print('snapshot: \\${snapshot.connectionState}, error: \\${snapshot.error}, data: \\${snapshot.data}');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '에러 발생: \\${snapshot.error}',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(
                      child: Text(
                        '사용자 정보가 없습니다.',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    );
                  }
                  final userInfo = snapshot.data;
                  print('UserInfo: $userInfo'); // 디버깅용
                  if (userInfo == null) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.grey[200],
                          child: const Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            '로그인이 필요합니다',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Color(0xFFFFD954),
                            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          child: const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: userInfo.profileImageUrl != null && userInfo.profileImageUrl!.isNotEmpty
                            ? NetworkImage(userInfo.profileImageUrl!)
                            : null,
                          child: (userInfo.profileImageUrl == null || userInfo.profileImageUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 40, color: Colors.grey)
                            : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                userInfo.nickname ?? '-',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansKR',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '닉네임: \\${userInfo.nickname ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                  fontFamily: 'NotoSansKR',
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Color(0xFFFFD954),
                            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            // 정보수정 페이지로 이동 (필요시 구현)
                          },
                          child: const Text(
                            '정보수정',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields, size: 36),
              title: const Text(
                '글씨 크기',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansKR',
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FontAndThemeSettingsScreen()),
                );
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            ListTile(
              leading: const Icon(Icons.notifications, size: 36),
              title: const Text(
                '알림 설정',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansKR',
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlarmSettingsScreen()),
                );
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            ListTile(
              leading: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '로그아웃',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                ],
              ),
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
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
              fontFamily: 'NotoSansKR',
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '로그아웃 하시겠습니까?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'NotoSansKR'),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontFamily: 'NotoSansKR',
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('로그아웃 중 오류가 발생했습니다: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontFamily: 'NotoSansKR',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 