import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettingsProvider>(context);
    final isDarkMode = appSettings.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final tileColor = isDarkMode ? Colors.grey[900] : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          FutureBuilder<UserInfo?>(
            future: AuthService.getUserInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: double.infinity,
                  color: tileColor,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Container(
                  width: double.infinity,
                  color: tileColor,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Text('오류가 발생했습니다.', style: TextStyle(fontSize: 20, color: textColor)),
                );
              } else {
                final userInfo = snapshot.data;
                final String name = userInfo?.nickname ?? '방문자';
                final String nickname = userInfo?.nickname ?? '-';
                return Container(
                  width: double.infinity,
                  color: tileColor,
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
                            Text(name, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                            SizedBox(height: 4),
                            Text('닉네임: $nickname', style: TextStyle(fontSize: 20, color: isDarkMode ? Colors.grey[400] : Colors.grey[700])),
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
          const Divider(height: 1, thickness: 1, color: Colors.grey),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.notifications, color: textColor, size: 32),
                  title: Text('알림 설정', style: TextStyle(fontSize: 22, color: textColor)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 24, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                  tileColor: tileColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AlarmSettingsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.file_download, color: textColor, size: 32),
                  title: Text('복약 기록 내보내기', style: TextStyle(fontSize: 22, color: textColor)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 24, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                  tileColor: tileColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExportMedicationScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.format_size, color: textColor, size: 32),
                  title: Text('글씨 크기/다크모드', style: TextStyle(fontSize: 22, color: textColor)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 24, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                  tileColor: tileColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FontAndThemeSettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 