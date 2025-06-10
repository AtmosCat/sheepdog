import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sheepdog/data/repository/sql_database.dart';
import 'package:sheepdog/firebase_options.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/theme/theme.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:sheepdog/ui/utils/fcm_utils.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    // Android 13(API 33) 이상에서만 필요
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }
  // iOS 권한 요청 (모든 버전에서 필요)
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.requestPermission();
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.notification != null) {
    final notification = message.notification!;
    final android = message.notification?.android;

    if (android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            '중요 알림',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }
  // 필요하다면 message.data를 활용해 추가 처리 가능
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQFLite DB 초기화 (앱 실행 시 최초 1회)
  await SqlDatabase.instance.database;

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 알림 권한 요청 (Android/iOS)
  await requestNotificationPermission();

  // FCM 권한 및 토큰 등록
  await FCMUtils().initFCM();

  // FCM 토큰 갱신 리스너 등록
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    FCMUtils().registerFcmTokenToServer(newToken);
  });

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 시스템 UI 세팅
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // FCM 토큰 확인 (디버깅용)
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM 토큰: $token");

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
