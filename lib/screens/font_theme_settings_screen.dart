import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../app_settings_provider.dart';

class FontAndThemeSettingsScreen extends StatefulWidget {
  const FontAndThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<FontAndThemeSettingsScreen> createState() => _FontAndThemeSettingsScreenState();
}

class _FontAndThemeSettingsScreenState extends State<FontAndThemeSettingsScreen> {
  double _fontSize = 24; // 고령자 기본값
  bool _isDarkMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('font_size') ?? 24;
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', _fontSize);
    await prefs.setBool('dark_mode', _isDarkMode);
    if (mounted) {
      final appSettings = Provider.of<AppSettingsProvider>(context, listen: false);
      await appSettings.updateFontSize(_fontSize);
      await appSettings.updateDarkMode(_isDarkMode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('설정이 저장되었습니다.', style: TextStyle(fontSize: 22)),
          backgroundColor: Color(0xFFFFD954),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFFFF8E1),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('글씨 크기/다크모드', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black)),
        backgroundColor: Color(0xFFFFD954),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('글씨 크기 조절', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFFFF3D1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFFD954), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('미리보기', style: TextStyle(fontSize: 22, color: Colors.black)),
                  const SizedBox(height: 12),
                  Text(
                    '이 글씨 크기로 앱이 보입니다.',
                    style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.text_decrease, size: 36, color: Colors.black),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 18,
                          max: 40,
                          divisions: 11,
                          label: '${_fontSize.toInt()}pt',
                          activeColor: Color(0xFFFFB300),
                          inactiveColor: Color(0xFFFFF3D1),
                          onChanged: (v) => setState(() => _fontSize = v),
                        ),
                      ),
                      Icon(Icons.text_increase, size: 36, color: Colors.black),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text('다크 모드', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Color(0xFFFFF3D1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFFD954), width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.dark_mode, size: 36, color: Colors.black),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      _isDarkMode ? '다크 모드 사용 중' : '라이트 모드 사용 중',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  Switch(
                    value: _isDarkMode,
                    onChanged: (v) => setState(() => _isDarkMode = v),
                    activeColor: Color(0xFFFFB300),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.save, size: 36, color: Colors.black),
                label: Text('저장', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFD954),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 