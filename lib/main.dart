import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheepdog/data/repository/sql_database.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/theme/theme.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';

// // --- navigatorKey는 알림 클릭 시 라우팅에 반드시 필요 ---
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// final Set<int> notificationSentTimerIds = {};

// Future<void> initNotification() async {
//   const AndroidInitializationSettings androidInit =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
//   final InitializationSettings initSettings = InitializationSettings(
//     android: androidInit,
//     iOS: iosInit,
//   );

//   await flutterLocalNotificationsPlugin.initialize(
//     initSettings,
//     onDidReceiveNotificationResponse: (details) {
//       // 알림 클릭 시 타이머 id로 이동
//       final timerId = details.payload;
//       if (timerId != null) {
//         navigatorKey.currentState?.push(
//           MaterialPageRoute(
//             builder: (_) => TimerRunningPage(timerId: int.parse(timerId)),
//           ),
//         );
//       }
//     },
//   );

//   // Android 권한 요청
//   await requestNotificationPermission();

//   // iOS 권한 요청
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         IOSFlutterLocalNotificationsPlugin
//       >()
//       ?.requestPermissions(alert: true, badge: true, sound: true);
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQFLite DB 초기화 (앱 실행 시 최초 1회)
  await SqlDatabase.instance.database;

  // // 알림 초기화
  // await initNotification();

  // // 파이어베이스 세팅
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 시스템 UI 세팅
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // // 구글 애드몹 설정
  // await MobileAds.instance.initialize();

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // navigatorKey: navigatorKey, // 알림 라우팅에 필수!
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: '쉽독',
      theme: lightTheme.copyWith(extensions: [AppColors.lightColorScheme]),
      darkTheme: darkTheme.copyWith(extensions: [AppColors.darkColorScheme]),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// Future<void> requestNotificationPermission() async {
//   if (Platform.isAndroid) {
//     // Android 13(API 33) 이상에서만 필요
//     final androidInfo = await DeviceInfoPlugin().androidInfo;
//     if (androidInfo.version.sdkInt >= 33) {
//       final status = await Permission.notification.status;
//       if (!status.isGranted) {
//         await Permission.notification.request();
//       }
//     }
//   }
// }
