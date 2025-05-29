// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _kakaoLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AuthService.loginWithKakao();
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 실패했습니다', style: TextStyle(fontFamily: 'NotoSansKR'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고
                const Icon(
                  Icons.medication,
                  size: 80,
                  color: Color(0xFFFDDB5C),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PILLCARE',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDDB5C),
                    fontFamily: 'NotoSansKR',
                  ),
                ),
                const SizedBox(height: 64),
                
                // 카카오 로그인 버튼
                _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFEE500)),
                    )
                  : InkWell(
                      onTap: _kakaoLogin,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE500),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.chat_bubble, color: Colors.black87),
                            SizedBox(width: 8),
                            Text(
                              '카카오 로그인',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'NotoSansKR',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 20),
                // 로그인 없이 진행 (테스트용)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => MainScreen()),
                    );
                  },
                  child: const Text('로그인 없이 진행 (테스트용)', style: TextStyle(fontFamily: 'NotoSansKR')),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}