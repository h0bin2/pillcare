import 'package:flutter/material.dart';

class PharmacyScreen extends StatelessWidget {
  const PharmacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 약국 데이터
    final pharmacies = [
      {
        'name': '지성약국',
        'distance': '570m',
        'address': '강릉시 범일로 604, 2층',
        'open': '08:30~18:00',
      },
      {
        'name': '소나무한약국',
        'distance': '0.92km',
        'address': '강릉시 경강로 1951',
        'open': '08:30~18:00',
      },
      {
        'name': '행복한약국',
        'distance': '0.65km',
        'address': '강릉시 구정면 범일로 442',
        'open': '08:30~18:00',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFD954),
                shape: StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () {
                // 전화내역 페이지 이동
              },
              icon: Icon(Icons.phone, color: Colors.black, size: 30),
              label: Text(
                '전화내역',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _PharmacyScreenWithCustomDrag(pharmacies: pharmacies),
    );
  }
}

class _PharmacyScreenWithCustomDrag extends StatefulWidget {
  final List<Map<String, String>> pharmacies;
  const _PharmacyScreenWithCustomDrag({required this.pharmacies});

  @override
  State<_PharmacyScreenWithCustomDrag> createState() => _PharmacyScreenWithCustomDragState();
}

class _PharmacyScreenWithCustomDragState extends State<_PharmacyScreenWithCustomDrag> {
  double sheetTopRatio = 0.45; // 0.0(지도 전체) ~ 0.95(리스트 전체)
  double minRatio = 0.0;
  double maxRatio = 1.0;
  double dragStartDy = 0;
  double dragStartRatio = 0;

  void _showCallDialog(BuildContext context, String pharmacyName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 전화상담요청 버튼
                Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    minLeadingWidth: 48,
                    leading: Icon(Icons.phone, size: 28, color: Colors.black87),
                    title: Text(
                      '전화상담요청',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
                    ),
                    onTap: () {
                      // 전화상담요청 기능
                      Navigator.pop(context);
                    },
                  ),
                ),
                // 전화걸기 버튼
                Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    minLeadingWidth: 48,
                    leading: Icon(Icons.phone, size: 28, color: Colors.black87),
                    title: Text(
                      '02-123-4567',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                    ),
                    subtitle: Text(
                      '전화걸기',
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    onTap: () {
                      // 실제 전화 기능 구현
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? kToolbarHeight;
    final sheetTop = height * sheetTopRatio;
    return Stack(
      children: [
        // 지도 (항상 배경)
        Positioned.fill(
          child: Container(
            color: Colors.grey[300],
            child: Center(
              child: Text(
                '지도 영역(구글/네이버 지도)',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ),
        // 리스트 시트
        AnimatedPositioned(
          duration: Duration(milliseconds: 200),
          curve: Curves.ease,
          top: sheetTop,
          left: 0,
          right: 0,
          height: height - sheetTop,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            elevation: 8,
            child: Column(
              children: [
                // 드래그 바 (여기서만 지도/리스트 비율 조절)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragStart: (details) {
                    dragStartDy = details.globalPosition.dy;
                    dragStartRatio = sheetTopRatio;
                  },
                  onVerticalDragUpdate: (details) {
                    final dragDy = details.globalPosition.dy - dragStartDy;
                    final newRatio = (dragStartRatio + dragDy / height).clamp(minRatio, maxRatio);
                    setState(() {
                      sheetTopRatio = newRatio;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 36,
                    alignment: Alignment.center,
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                // 리스트 영역 (여기서는 스크롤만 가능)
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: true,
                    child: ListView.separated(
                      padding: EdgeInsets.only(top: 0, bottom: 24),
                      itemCount: widget.pharmacies.length,
                      separatorBuilder: (context, idx) => Divider(thickness: 1, height: 1),
                      itemBuilder: (context, idx) {
                        final p = widget.pharmacies[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      p['name']!,
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 26,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '${p['distance']}   ${p['address']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '영업 중 ',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: p['open'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(right: 8.0, bottom: 4.0),
                                child: IconButton(
                                  icon: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Color(0xFFFFD954), width: 3),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.phone, color: Color(0xFFFFD954), size: 40),
                                    ),
                                  ),
                                  iconSize: 60,
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(minWidth: 60, minHeight: 60),
                                  onPressed: () => _showCallDialog(context, p['name']!),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 