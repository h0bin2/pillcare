// lib/screens/intro_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import 'main_screen.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 딜레이 추가 (애니메이션을 위해)
    await Future.delayed(const Duration(seconds: 2));
    
    // 로그인 상태 확인
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isLoggedIn ? MainScreen() : LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDDB5C), // 노란색 배경
      body: Center(
        child: const Text(
          'PILLCARE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}