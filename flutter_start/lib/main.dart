import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/intro_screen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'app_settings_provider.dart';

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

  await NaverMapSdk.instance.initialize(
      clientId: 'c22uzm0ayz',
      onAuthFailed: (ex) {
        print("********* 네이버맵 인증오류 : $ex *********");
      });

  final appSettings = AppSettingsProvider();
  await appSettings.loadSettings();

  runApp(
    ChangeNotifierProvider.value(
      value: appSettings,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, appSettings, child) {
        return MaterialApp(
          title: 'PILLCARE',
          theme: ThemeData(
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: appSettings.isDarkMode ? Colors.black : Colors.white,
            brightness: appSettings.isDarkMode ? Brightness.dark : Brightness.light,
            fontFamily: 'NotoSansKR',
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
          ],
          home: const IntroScreen(),
        );
      },
    );
  }
}
