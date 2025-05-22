import 'package:flutter/material.dart';

class FontThemeScreen extends StatefulWidget {
  const FontThemeScreen({Key? key}) : super(key: key);

  @override
  State<FontThemeScreen> createState() => _FontThemeScreenState();
}

class _FontThemeScreenState extends State<FontThemeScreen> {
  double _fontSize = 22; // 기본값(고령자용)
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('글씨 크기/다크모드', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
        backgroundColor: Color(0xFFFFD954),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('글씨 크기 조절', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.text_fields, size: 36, color: _isDarkMode ? Colors.white : Colors.black),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 16,
                    max: 36,
                    divisions: 10,
                    label: '${_fontSize.toInt()}pt',
                    onChanged: (v) => setState(() => _fontSize = v),
                    activeColor: Color(0xFFFFB300),
                  ),
                ),
                Text('${_fontSize.toInt()}pt', style: TextStyle(fontSize: 22, color: _isDarkMode ? Colors.white : Colors.black)),
              ],
            ),
            const SizedBox(height: 32),
            Text('다크 모드', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.dark_mode, size: 36, color: _isDarkMode ? Colors.yellow[200] : Colors.black),
                const SizedBox(width: 16),
                Expanded(
                  child: Switch(
                    value: _isDarkMode,
                    onChanged: (v) => setState(() => _isDarkMode = v),
                    activeColor: Color(0xFFFFB300),
                  ),
                ),
                Text(_isDarkMode ? 'ON' : 'OFF', style: TextStyle(fontSize: 22, color: _isDarkMode ? Colors.white : Colors.black)),
              ],
            ),
            const SizedBox(height: 40),
            Text('미리보기', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[900] : Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '이 글씨 크기와 색상으로 앱이 보입니다.',
                style: TextStyle(fontSize: _fontSize, color: _isDarkMode ? Colors.white : Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 실제 앱 전체에 적용하려면 Provider, SharedPreferences 등 연동 필요
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('설정이 미리보기로만 적용됩니다. (앱 전체 적용은 추후 지원)')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFD954),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                child: Text('적용하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 