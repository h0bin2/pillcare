class _FontAndThemeSettingsScreenState extends State<FontAndThemeSettingsScreen> {
  double _fontSize = 24;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('설정이 저장되었습니다.', style: TextStyle(fontSize: 22)),
          backgroundColor: Color(0xFFFFD954),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('글씨 크기 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black)),
        backgroundColor: Color(0xFFFFD954),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
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