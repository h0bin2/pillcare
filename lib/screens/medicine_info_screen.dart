import 'package:flutter/material.dart';

class MedicineInfoScreen extends StatefulWidget {
  final String name;
  final String imagePath;
  final List<String> effects;
  final List<String> usage;
  final List<String> cautions;

  const MedicineInfoScreen({
    required this.name,
    required this.imagePath,
    required this.effects,
    required this.usage,
    required this.cautions,
    Key? key,
  }) : super(key: key);

  @override
  State<MedicineInfoScreen> createState() => _MedicineInfoScreenState();
}

class _MedicineInfoScreenState extends State<MedicineInfoScreen> {
  int _selectedTab = 0;

  final List<String> tabTitles = ['효과효능', '용법용량', '주의사항'];
  final List<IconData> tabIcons = [
    Icons.medication, // 알약 아이콘
    Icons.science,    // 비커 아이콘
    Icons.warning_amber_rounded,
  ];

  List<List<String>> get tabContents => [
    widget.effects,
    widget.usage,
    widget.cautions,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.name,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 1.2,
            fontFamily: 'NotoSansKR',
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 약 이미지
            Container(
              height: 280,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Image.asset(
                  widget.imagePath,
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.medication, color: Colors.white, size: 60),
                ),
              ),
            ),
            // 탭 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (idx) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == idx ? Color(0xFFFFD954) : Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _selectedTab == idx ? Color(0xFFFFD954) : Colors.black26),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedTab = idx;
                      });
                    },
                    child: Column(
                      children: [
                        Icon(tabIcons[idx], size: 44, color: Colors.black, weight: 800),
                        SizedBox(height: 6),
                        Text(
                          tabTitles[idx],
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Colors.black,
                            letterSpacing: 1.1,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 16),
            // 내용 박스
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFFFD954), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tabContents[_selectedTab]
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text('• $e', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 