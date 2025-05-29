import 'package:flutter/material.dart';

class ExportMedicationScreen extends StatefulWidget {
  const ExportMedicationScreen({Key? key}) : super(key: key);

  @override
  State<ExportMedicationScreen> createState() => _ExportMedicationScreenState();
}

class _ExportMedicationScreenState extends State<ExportMedicationScreen> {
  String _selectedPeriod = '전체';
  String _selectedFormat = 'CSV';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('복약 기록 내보내기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black, fontFamily: 'NotoSansKR')),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('내보낼 기간', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('전체', style: TextStyle(fontSize: 22, fontFamily: 'NotoSansKR')),
                      selected: _selectedPeriod == '전체',
                      onSelected: (v) => setState(() => _selectedPeriod = '전체'),
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: Text('최근 1개월', style: TextStyle(fontSize: 22, fontFamily: 'NotoSansKR')),
                      selected: _selectedPeriod == '최근 1개월',
                      onSelected: (v) => setState(() => _selectedPeriod = '최근 1개월'),
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: Text('직접 선택', style: TextStyle(fontSize: 22, fontFamily: 'NotoSansKR')),
                      selected: _selectedPeriod == '직접 선택',
                      onSelected: (v) => setState(() => _selectedPeriod = '직접 선택'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Text('내보내기 형식', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('CSV', style: TextStyle(fontSize: 22, fontFamily: 'NotoSansKR')),
                      selected: _selectedFormat == 'CSV',
                      onSelected: (v) => setState(() => _selectedFormat = 'CSV'),
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: Text('PDF', style: TextStyle(fontSize: 22, fontFamily: 'NotoSansKR')),
                      selected: _selectedFormat == 'PDF',
                      onSelected: (v) => setState(() => _selectedFormat = 'PDF'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.file_download, size: 40),
                  label: Text('내보내기', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFD954),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // TODO: 실제 내보내기 기능 구현
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('내보내기 준비 중', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR')),
                        content: Text('실제 내보내기 기능은 추후 지원됩니다.', style: TextStyle(fontSize: 20, fontFamily: 'NotoSansKR')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('확인', style: TextStyle(fontSize: 20, fontFamily: 'NotoSansKR')),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '복약 기록을 파일로 내보내거나, 가족·의료진과 공유할 수 있습니다.\n내보내기 형식과 기간을 선택한 뒤 내보내기 버튼을 눌러주세요.',
                style: TextStyle(fontSize: 22, color: Colors.black87, height: 1.5, fontFamily: 'NotoSansKR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 