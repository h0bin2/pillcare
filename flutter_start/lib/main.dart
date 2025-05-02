import 'package:flutter/material.dart';
import 'screens/intro_screen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('.env 파일 로드 실패: $e');
  }

  String? nativeAppKey = 'f05090355f9d1379adbc5395f7165d18';
  if (nativeAppKey != null) {
    try {
      KakaoSdk.init(nativeAppKey: nativeAppKey);
      print('Kakao SDK 초기화 성공');
    } catch (e) {
      print('Kakao SDK 초기화 실패: $e');
    }
  } else {
    print('NATIVE_APP_KEY가 .env 파일에 설정되지 않았습니다.');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PILLCARE',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const IntroScreen(),
    );
  }
}
