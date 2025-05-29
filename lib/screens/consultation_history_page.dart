import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/consultation_info.dart';

final List<ConsultationInfo> dummyConsultations = [
  ConsultationInfo(
    id: 1,
    userId: 1001,
    pharmacyId: 101,
    pharmacyName: '조은약국',
    createdAt: DateTime(2025, 5, 23),
    updatedAt: DateTime(2025, 5, 23),
    status: '완료',
    history: '정기구독 신청',
  ),
  ConsultationInfo(
    id: 2,
    userId: 1001,
    pharmacyId: 101,
    pharmacyName: '조은약국',
    createdAt: DateTime(2025, 5, 23),
    updatedAt: DateTime(2025, 5, 23),
    status: '완료',
    history: '전화상담요청',
  ),
];

class ConsultationHistoryPage extends StatelessWidget {
  final Future<List<ConsultationInfo>>? consultationHistoryFuture;
  const ConsultationHistoryPage({Key? key, this.consultationHistoryFuture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('상담 내역', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'NotoSansKR')),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ConsultationInfo>>(
        future: consultationHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('상담 내역을 불러오는 중 오류가 발생했습니다.', style: TextStyle(color: Colors.red, fontFamily: 'NotoSansKR')));
          }
          final consultations = snapshot.data ?? [];
          if (consultations.isEmpty) {
            return Center(child: Text('최근 상담 내역이 없습니다.', style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontFamily: 'NotoSansKR')));
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: consultations.length,
            itemBuilder: (context, index) {
              final consultation = consultations[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          consultation.pharmacyName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          DateFormat('yyyy.MM.dd (E)', 'ko').format(consultation.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      consultation.history,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'NotoSansKR',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 