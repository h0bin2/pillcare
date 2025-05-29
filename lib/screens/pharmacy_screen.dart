import 'package:flutter/material.dart';
import 'pharmacy_detail_screen.dart';
import 'subscription_screen.dart';
import '../models/user_info.dart';

class PharmacyScreen extends StatelessWidget {
  final UserInfo? userInfo;
  const PharmacyScreen({this.userInfo, super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 약국 데이터
    final pharmacies = [
      {
        'name': '지성약국',
        'distance': '570m',
        'address': '강릉시 범일로 604, 2층',
        'open': '08:30~18:00',
        'phone': '033-123-4567',
      },
      {
        'name': '소나무한약국',
        'distance': '0.92km',
        'address': '강릉시 경강로 1951',
        'open': '08:30~18:00',
        'phone': '033-234-5678',
      },
      {
        'name': '행복한약국',
        'distance': '0.65km',
        'address': '강릉시 구정면 범일로 442',
        'open': '08:30~18:00',
        'phone': '033-345-6789',
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
        actions: [],
      ),
      body: _PharmacyScreenWithCustomDrag(pharmacies: pharmacies, userInfo: userInfo),
    );
  }
}

class _PharmacyScreenWithCustomDrag extends StatefulWidget {
  final List<Map<String, String>> pharmacies;
  final UserInfo? userInfo;
  const _PharmacyScreenWithCustomDrag({required this.pharmacies, this.userInfo});

  @override
  State<_PharmacyScreenWithCustomDrag> createState() => _PharmacyScreenWithCustomDragState();
}

class _PharmacyScreenWithCustomDragState extends State<_PharmacyScreenWithCustomDrag> {
  double sheetTopRatio = 0.45;
  double minRatio = 0.1;
  double maxRatio = 0.85;
  double dragStartDy = 0;
  double dragStartRatio = 0;

  void _showCenterRequestMessage(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedOpacity(
        opacity: 1.0,
        duration: Duration(milliseconds: 200),
        child: Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(0.08),
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                decoration: BoxDecoration(
                  color: Color(0xFFFDF6D9).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Color(0xFFFFD954),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '요청 되었습니다',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                        fontFamily: 'NotoSansKR',
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(Duration(milliseconds: 1200), () {
      overlayEntry.remove();
    });
  }

  void _showCallDialog(BuildContext context, String pharmacyName, String phoneNumber, {Map<String, String>? pharmacy}) {
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21, fontFamily: 'NotoSansKR'),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      _showCenterRequestMessage(context);
                    },
                  ),
                ),
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
                      phoneNumber.isNotEmpty ? phoneNumber : '전화번호 없음',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, fontFamily: 'NotoSansKR'),
                    ),
                    subtitle: Text(
                      '전화걸기',
                      style: TextStyle(fontSize: 18, color: Colors.black87, fontFamily: 'NotoSansKR'),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // 실제 전화걸기 기능은 필요시 추가
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
    final sheetTop = height * sheetTopRatio;

    return Stack(
      children: [
        // 지도 (항상 배경)
        Positioned.fill(
          child: Container(
            color: Colors.grey[200],
            child: Center(
              child: Text('지도 영역 (NaverMap)', style: TextStyle(fontSize: 22, color: Colors.grey)),
            ),
            // 실제 배포 시 아래 주석 해제 후 NaverMap 위젯 사용
            // child: NaverMap(
            //   options: NaverMapViewOptions(
            //     initialCameraPosition: NCameraPosition(
            //       target: NLatLng(37.5666102, 126.9783881),
            //       zoom: 15,
            //     ),
            //     locationButtonEnable: true,
            //   ),
            // ),
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
                // 드래그 바 (GestureDetector 추가)
                GestureDetector(
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
                // 리스트 영역
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
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PharmacyDetailScreen(pharmacy: p, userInfo: widget.userInfo),
                                ),
                              );
                            },
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
                                          fontFamily: 'NotoSansKR',
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        p['distance']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          fontFamily: 'NotoSansKR',
                                        ),
                                      ),
                                      Text(
                                        p['address']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          fontFamily: 'NotoSansKR',
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
                                    onPressed: () => _showCallDialog(context, p['name']!, p['phone'] ?? '', pharmacy: p),
                                  ),
                                ),
                              ],
                            ),
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

// 아래는 복구된 PharmacyDetailScreen 클래스입니다.
class PharmacyDetailScreen extends StatelessWidget {
  final Map<String, String> pharmacy;
  final UserInfo? userInfo;
  const PharmacyDetailScreen({required this.pharmacy, this.userInfo, Key? key}) : super(key: key);

  void _showCenterRequestMessage(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedOpacity(
        opacity: 1.0,
        duration: Duration(milliseconds: 200),
        child: Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(0.08),
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                decoration: BoxDecoration(
                  color: Color(0xFFFDF6D9).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Color(0xFFFFD954),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '요청 되었습니다',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                        fontFamily: 'NotoSansKR',
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(Duration(milliseconds: 1200), () {
      overlayEntry.remove();
    });
  }

  void _showCallDialog(BuildContext context, String pharmacyName, String phoneNumber, {Map<String, String>? pharmacy}) {
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21, fontFamily: 'NotoSansKR'),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      _showCenterRequestMessage(context);
                    },
                  ),
                ),
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
                      phoneNumber.isNotEmpty ? phoneNumber : '전화번호 없음',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, fontFamily: 'NotoSansKR'),
                    ),
                    subtitle: Text(
                      '전화걸기',
                      style: TextStyle(fontSize: 18, color: Colors.black87, fontFamily: 'NotoSansKR'),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // 실제 전화걸기 기능은 필요시 추가
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
    final double imageHeight = MediaQuery.of(context).size.height * 0.5;
    
    // 약국 이름에서 첫 글자 추출
    final String firstChar = (pharmacy['name'] ?? '약').substring(0, 1);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          pharmacy['name'] ?? '약국 상세',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 이미지 박스
          Container(
            height: imageHeight,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
            ),
            child: Stack(
              children: [
                // 배경 패턴
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: CustomPaint(
                      painter: PatternPainter(),
                    ),
                  ),
                ),
                // 중앙 약국 이름 첫 글자
                Center(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFD954).withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        firstChar,
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansKR',
                        ),
                      ),
                    ),
                  ),
                ),
                // 약국 이름
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Text(
                    pharmacy['name'] ?? '',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'NotoSansKR',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // 약국 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      (pharmacy['distance'] ?? '') + ' ',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black, fontFamily: 'NotoSansKR'),
                    ),
                    Expanded(
                      child: Text(
                        pharmacy['address'] ?? '',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'NotoSansKR'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if ((pharmacy['phone'] ?? '').isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.phone, size: 22, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        pharmacy['phone']!,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'NotoSansKR'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // 버튼 2개
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFF3D1),
                        foregroundColor: Colors.black,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      onPressed: () {
                        // 정기구독 상세 페이지에서도 전화 아이콘과 동일한 다이얼로그를 띄움
                        _showCallDialog(context, pharmacy['name'] ?? '', pharmacy['phone'] ?? '', pharmacy: pharmacy);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, size: 54, color: Colors.black),
                          SizedBox(height: 14),
                          Text('전화걸기', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black, fontFamily: 'NotoSansKR')),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFF3D1),
                        foregroundColor: Colors.black,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                '정기구독 신청',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  fontFamily: 'NotoSansKR',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              content: Text(
                                '${pharmacy['name']}에서 정기구독을 신청하시겠습니까?',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'NotoSansKR'),
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(
                                    '취소',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 22,
                                      fontFamily: 'NotoSansKR',
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    '신청하기',
                                    style: TextStyle(
                                      color: Color(0xFFFFB300),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'NotoSansKR',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirmed == true) {
                          // 실제 상담 신청 기능은 필요시 추가
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('정기구독 신청이 완료되었습니다.', style: TextStyle(fontFamily: 'NotoSansKR'))),
                          );
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services, size: 54, color: Colors.black),
                          SizedBox(height: 14),
                          Text('정기구독', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black, fontFamily: 'NotoSansKR')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 배경 패턴을 그리는 CustomPainter
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final spacing = 30.0;
    for (var i = 0.0; i < size.width; i += spacing) {
      for (var j = 0.0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 