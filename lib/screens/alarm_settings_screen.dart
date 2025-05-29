import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_settings_provider.dart';

class AlarmSettingsScreen extends StatelessWidget {
  const AlarmSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettingsProvider>(context);
    final isDarkMode = appSettings.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final tileColor = isDarkMode ? Colors.grey[900] : Color(0xFFFFF8E1);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('알림 관리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: textColor)),
        backgroundColor: Color(0xFFFFD954),
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: Icon(Icons.alarm, color: Color(0xFFFFB300), size: 32),
            title: Text('아침 약 복용', style: TextStyle(fontSize: 22, color: textColor)),
            subtitle: Text('매일 오전 8:00', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.black87)),
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeColor: Color(0xFFFFB300),
            ),
            tileColor: tileColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          ListTile(
            leading: Icon(Icons.alarm, color: Color(0xFFFFB300), size: 32),
            title: Text('점심 약 복용', style: TextStyle(fontSize: 22, color: textColor)),
            subtitle: Text('매일 오후 1:00', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.black87)),
            trailing: Switch(
              value: false,
              onChanged: (v) {},
              activeColor: Color(0xFFFFB300),
            ),
            tileColor: tileColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          ListTile(
            leading: Icon(Icons.alarm, color: Color(0xFFFFB300), size: 32),
            title: Text('저녁 약 복용', style: TextStyle(fontSize: 22, color: textColor)),
            subtitle: Text('매일 오후 7:00', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.black87)),
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeColor: Color(0xFFFFB300),
            ),
            tileColor: tileColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ],
      ),
    );
  }
} 