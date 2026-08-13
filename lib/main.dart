import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/data/provider/providers.dart';
import 'package:sheepdog/data/repository/sql_database.dart';
import 'package:sheepdog/firebase_options.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/theme/theme.dart';
import 'package:sheepdog/ui/ads/admob_service.dart';
import 'package:sheepdog/ui/pages/widgets/main_shell_page.dart';
import 'dart:io';
import 'package:sheepdog/ui/pages/mypage/notification_intro_page.dart';
import 'package:sheepdog/ui/utils/fcm_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('onBackgroundMessage called');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SqlDatabase.instance.database;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  if (message.notification != null) {
    final notification = message.notification!;
    // final notificationData = {
    //   'title': notification.title ?? '',
    //   'body': notification.body ?? '',
    //   'receivedAt': DateTime.now().toIso8601String(),
    //   'read': false,
    // };
    // try {
    //   await LocalNotificationRepository().insertNotification(notificationData);
    //   print('백그라운드 알림 내역 저장 성공');
    // } catch (e, st) {
    //   print('백그라운드 알림 저장 오류: $e\n$st');
    // }

    final android = message.notification?.android;
    if (android != null) {
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            '중요 알림',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'icon10',
          ),
        ),
      );
    }
  }
}

// 기기 고유 ID 생성 함수
Future<String> _getDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? Uuid().v4();
  }
  return Uuid().v4();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQFLite DB 초기화 (앱 실행 시 최초 1회, 마이그레이션 포함)
  await SqlDatabase.instance.reopen();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 익명 로그인 초기화
  await FirebaseAuth.instance.signInAnonymously();

  // 인앱결제 초기화
  final InAppPurchase iap = InAppPurchase.instance;
  if (await iap.isAvailable()) {
    await iap.restorePurchases(); // 기존 구매 복원
  }
  // Firestore에 유저 상태 초기화
  final user = FirebaseAuth.instance.currentUser!;
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final doc = await userDoc.get();
  if (!doc.exists) {
    await userDoc.set({
      'isPremium': false,
      'createdAt': DateTime.now().toIso8601String(),
      'deviceId': await _getDeviceId(), // 기기 고유 ID
    });
  }
  final isPremium = doc.exists && doc.data()?['isPremium'] == true;

  await AdMobService.initialize();
  // 알림 권한은 첫 안내 화면 / 설정에서 동의 후에만 요청
  // 알림 채널 생성 (Android)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    '중요 알림',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // 플러그인 초기화 (전역 인스턴스 사용)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // iOS 포그라운드 알림 표시 옵션
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // FCM 토큰만 확보 (권한 미요청). 동의 전이면 토큰이 null일 수 있음.
  await FCMUtils().initFCM(requestPermission: false);

  // FCM 토큰 갱신 리스너 등록
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    FCMUtils().registerFcmTokenToServer(newToken);
  });

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 디버깅용 FCM 메시지 수신 로그
  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('포그라운드 알림 수신: ${message.messageId}');
  });
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('백그라운드에서 열린 알림: ${message.messageId}');
  });

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

  runApp(
    MultiProvider(
      providers: appProviders,
      child: MyApp(showStartupAd: !isPremium),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.showStartupAd});

  final bool showStartupAd;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _bootstrapping = true;
  bool _showIntro = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final introFuture = _loadIntroState();
    // 앱 오프닝 광고 비활성화 (AdMob 정책)
    final showIntro = await introFuture;

    if (!mounted) return;
    setState(() {
      _showIntro = showIntro;
      _bootstrapping = false;
    });
  }

  Future<bool> _loadIntroState() async {
    final prefs = await SharedPreferences.getInstance();
    var shown =
        prefs.getBool(FCMUtils.notificationIntroShownKey) ?? false;

    // 기존 유저: 이미 OS 알림 권한이 있으면 안내를 다시 띄우지 않음
    if (!shown) {
      final granted = await FCMUtils().isNotificationPermissionGranted();
      if (granted) {
        await prefs.setBool(FCMUtils.notificationIntroShownKey, true);
        // 기존 onNotify 값을 paymentDayNotify로 이관
        final settings = await FCMUtils().getPaymentDaySettings();
        await FCMUtils().savePaymentDaySettings(
          enabled: settings['enabled'] as bool? ?? false,
          hour: settings['hour'] as int? ?? 9,
          minute: settings['minute'] as int? ?? 0,
        );
        shown = true;
      }
    }

    return !shown;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: '쉽독',
      theme: lightTheme.copyWith(extensions: [AppColors.lightColorScheme]),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: _bootstrapping
          ? const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            )
          : _showIntro
              ? NotificationIntroPage(
                  onFinished: () {
                    setState(() => _showIntro = false);
                  },
                )
              : const MainShellPage(),
    );
  }
}
