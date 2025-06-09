import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sheepdog/data/repository/sql_database.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/theme/theme.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotification() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  final InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      // 알림 클릭 시 라우팅 처리 (예: 특정 페이지로 이동)
      // final payload = details.payload;
      // if (payload != null) {
      //   navigatorKey.currentState?.push(...);
      // }
    },
  );

  // Android 권한 요청
  await requestNotificationPermission();

  // iOS 권한 요청
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}

Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    // Android 13(API 33) 이상에서만 필요
    // (permission_handler 패키지 필요)
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQFLite DB 초기화 (앱 실행 시 최초 1회)
  await SqlDatabase.instance.database;

  // 알림 초기화
  await initNotification();

  // 시스템 UI 세팅
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 알림 라우팅에 필수!
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
