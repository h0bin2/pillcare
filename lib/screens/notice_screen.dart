import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NoticeItem {
  final String brand;
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  NoticeItem({
    required this.brand,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'brand': brand,
    'time': time,
    'title': title,
    'subtitle': subtitle,
    'icon': icon.codePoint,
  };

  factory NoticeItem.fromJson(Map<String, dynamic> json) => NoticeItem(
    brand: json['brand'],
    time: json['time'],
    title: json['title'],
    subtitle: json['subtitle'],
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
  );
}

class NoticeStorage {
  static const String _key = 'notices';

  static Future<List<NoticeItem>> loadNotices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => NoticeItem.fromJson(e)).toList();
  }

  static Future<void> saveNotices(List<NoticeItem> notices) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(notices.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> addNotice(NoticeItem notice) async {
    final notices = await loadNotices();
    notices.insert(0, notice); // 최신 알림이 위로
    await saveNotices(notices);
  }
}

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({Key? key}) : super(key: key);

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  late Future<List<NoticeItem>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _noticesFuture = NoticeStorage.loadNotices();
  }

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
          '알림',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<NoticeItem>>(
        future: _noticesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                '최근 공지사항이 없습니다.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansKR',
                ),
              ),
            );
          }
          final notices = snapshot.data!;
          return Container(
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              itemCount: notices.length,
              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
              itemBuilder: (context, index) {
                final notice = notices[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  leading: Icon(notice.icon, size: 32, color: Colors.grey),
                  title: Text(
                    notice.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notice.subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontFamily: 'NotoSansKR',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${notice.brand}  ${notice.time}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontFamily: 'NotoSansKR',
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
                  // onTap: () => _showNoticeDetail(notice),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 