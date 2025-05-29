import 'package:flutter/material.dart';
import '../models/consultation_info.dart';
import '../services/auth_service.dart';

class PharmacyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pharmacy;
  const PharmacyDetailScreen({required this.pharmacy, Key? key}) : super(key: key);

  void _showCallDialog(BuildContext context, String pharmacyName, String phoneNumber) {
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
                    ),
                    onTap: () {
                      Navigator.pop(context);
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
                      phoneNumber,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                    ),
                    subtitle: Text(
                      '전화걸기',
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      }
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
    // 항상 임시 이미지 사용
    final String imageAsset = 'https://via.placeholder.com/400x200.png?text=Pharmacy';
    final double imageHeight = MediaQuery.of(context).size.height * 0.5;
    final String pharmacyName = pharmacy['name'] ?? '약국';
    final String phoneNumber = pharmacy['phone'] ?? '02-123-4567';
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            pharmacyName,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PhoneHistoryScreen()),
                  );
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print('FAB 클릭됨');
            showDialog(
              context: context,
              builder: (context) => AlertDialog(content: Text('FAB 다이얼로그')), 
            );
          },
          child: Icon(Icons.add),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 이미지 박스
              Container(
                height: imageHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  image: DecorationImage(
                    image: NetworkImage(
                      imageAsset,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey));
                      },
                    ),
                    fit: BoxFit.cover,
                  ),
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
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black),
                        ),
                        Expanded(
                          child: Text(
                            pharmacy['address'] ?? '',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Text('영업 중 ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(
                          pharmacy['open'] ?? '',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 버튼 2개
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
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
                          print('전화걸기 버튼 클릭됨');
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: Text('테스트 다이얼로그'),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone, size: 54, color: Colors.black),
                            SizedBox(height: 14),
                            Text('전화걸기', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
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
                        onPressed: () {
                          showDialog(
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
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                content: Text(
                                  '{pharmacyName}에서 정기구독을 신청하시겠습니까?',
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
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('정기구독 신청이 완료되었습니다.'),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Color(0xFFFFD954),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '신청하기',
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medical_services, size: 54, color: Colors.black),
                            SizedBox(height: 14),
                            Text('정기구독', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16), // 하단 여유 공간
            ],
          ),
        ),
      ),
    );
  }
}

class PhoneHistoryScreen extends StatefulWidget {
  const PhoneHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PhoneHistoryScreen> createState() => _PhoneHistoryScreenState();
}

class _PhoneHistoryScreenState extends State<PhoneHistoryScreen> {
  late Future<List<ConsultationInfo>> _consultationHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadConsultationHistory();
  }

  Future<void> _loadConsultationHistory() async {
    final userInfo = await AuthService.getCurrentUserInfo();
    if (userInfo != null && userInfo['id'] != null) {
      setState(() {
        _consultationHistoryFuture = AuthService.getConsultationHistory(userInfo['id']);
      });
    } else {
      setState(() {
        _consultationHistoryFuture = Future.value([]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('전화내역', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<ConsultationInfo>>(
        future: _consultationHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('전화내역을 불러오는 중 오류가 발생했습니다.', style: TextStyle(color: Colors.red)));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final consultations = snapshot.data!;
            return ListView.separated(
              padding: EdgeInsets.all(20),
              itemCount: consultations.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
              itemBuilder: (context, index) {
                final c = consultations[index];
                return ListTile(
                  leading: Icon(Icons.phone, color: Color(0xFFFFB300), size: 36),
                  title: Text(c.pharmacyName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.formattedCreatedAt, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                      SizedBox(height: 2),
                      Text(c.history, style: TextStyle(fontSize: 16, color: Colors.black)),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            );
          } else {
            return Center(child: Text('최근 전화내역이 없습니다.', style: TextStyle(fontSize: 18, color: Colors.grey[700])));
          }
        },
      ),
    );
  }
} 