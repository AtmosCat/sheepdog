import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/local_notification_repository.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

class FCMUtils {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// FCM 권한 요청 및 토큰 획득
  Future<String?> initFCM() async {
    await FirebaseMessaging.instance.requestPermission();
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
    return token;
  }

  void setupInteractedMessage(BuildContext context) {
    // iOS에서 포그라운드 알림 표시 옵션 활성화 (필요시)
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // 1. 알림 내역 저장
      await saveNotificationHistory(message);

      // 2. 포그라운드에서도 항상 알림 표시
      if (notification != null) {
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
            ),
            iOS: DarwinNotificationDetails(), // iOS도 알림 표시
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // 알림 클릭 시 Homepage로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomePage()),
        (route) => false,
      );
    });
  }

  Future<void> registerFcmTokenToServer(String token) async {
    const String serverUrl =
        'https://asia-northeast3-sheepdog-fa14d.cloudfunctions.net/saveUserNotificationSettings';
    await http.post(
      Uri.parse(serverUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fcmToken': token}),
    );
  }

  /// 알림 내역 저장 메서드
  Future<void> saveNotificationHistory(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final notificationData = {
      'title': notification.title ?? '',
      'body': notification.body ?? '',
      'receivedAt': DateTime.now().toIso8601String(),
      'read': false,
    };

    await LocalNotificationRepository().insertNotification(notificationData);
  }

  /// 유저별 3문서(결제 전/당일/후)만 서버에 저장하는 방식
  Future<void> saveUserNotificationSettings({
    required List<SubscriptionService> subscriptions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      print('FCM 토큰이 없습니다.');
      return;
    }

    // 알림 설정값
    final beforeNotify = prefs.getBool('beforeNotify') ?? true;
    final beforeHour = prefs.getInt('beforeHour') ?? 9;
    final beforeMinute = prefs.getInt('beforeMinute') ?? 0;

    final onNotify = prefs.getBool('onNotify') ?? true;
    final onHour = prefs.getInt('onHour') ?? 9;
    final onMinute = prefs.getInt('onMinute') ?? 0;

    final afterNotify = prefs.getBool('afterNotify') ?? false;
    final afterHour = prefs.getInt('afterHour') ?? 18;
    final afterMinute = prefs.getInt('afterMinute') ?? 0;

    // 구독 리스트에서 다음 결제일/알림 메시지 계산
    DateTime? nextBeforeDate;
    DateTime? nextOnDate;
    DateTime? nextAfterDate;
    List<String> beforeNames = [];
    List<String> onNames = [];
    List<String> afterNames = [];

    for (final sub in subscriptions) {
      final dates = getFuturePaymentDates(sub, maxCount: 1);
      if (dates.isEmpty) continue;
      final paymentDate = dates.first;

      // 결제 전 알림: 하루 전
      final beforeDate = DateTime(
        paymentDate.year,
        paymentDate.month,
        paymentDate.day,
        beforeHour,
        beforeMinute,
      ).subtract(const Duration(days: 1));
      if (beforeNotify &&
          (nextBeforeDate == null || beforeDate.isBefore(nextBeforeDate))) {
        nextBeforeDate = beforeDate;
        beforeNames = [sub.name];
      } else if (beforeNotify &&
          nextBeforeDate != null &&
          beforeDate.isAtSameMomentAs(nextBeforeDate)) {
        beforeNames.add(sub.name);
      }

      // 결제 당일 알림
      final onDate = DateTime(
        paymentDate.year,
        paymentDate.month,
        paymentDate.day,
        onHour,
        onMinute,
      );
      if (onNotify && (nextOnDate == null || onDate.isBefore(nextOnDate))) {
        nextOnDate = onDate;
        onNames = [sub.name];
      } else if (onNotify &&
          nextOnDate != null &&
          onDate.isAtSameMomentAs(nextOnDate)) {
        onNames.add(sub.name);
      }

      // 결제 후 알림: afterDays 후
      final afterDate = DateTime(
        paymentDate.year,
        paymentDate.month,
        paymentDate.day,
        afterHour,
        afterMinute,
      );
      if (afterNotify &&
          (nextAfterDate == null || afterDate.isBefore(nextAfterDate))) {
        nextAfterDate = afterDate;
        afterNames = [sub.name];
      } else if (afterNotify &&
          nextAfterDate != null &&
          afterDate.isAtSameMomentAs(nextAfterDate)) {
        afterNames.add(sub.name);
      }
    }

    // 서버로 보낼 데이터 구조 (fcmToken을 userId로 사용)
    final notifications = [
      {
        'type': 'before',
        'notifyOn': beforeNotify,
        'notifyTime':
            '${beforeHour.toString().padLeft(2, '0')}:${beforeMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': nextBeforeDate?.toUtc().toIso8601String(),
        'message': beforeNames.isNotEmpty
            ? '내일 결제 예정인 구독이 있습니다.\n${beforeNames.join(', ')}'
            : '',
        'fcmToken': fcmToken,
      },
      {
        'type': 'on',
        'notifyOn': onNotify,
        'notifyTime':
            '${onHour.toString().padLeft(2, '0')}:${onMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': nextOnDate?.toUtc().toIso8601String(),
        'message': onNames.isNotEmpty
            ? '오늘 결제 예정인 구독이 있습니다.\n${onNames.join(', ')}'
            : '',
        'fcmToken': fcmToken,
      },
      {
        'type': 'after',
        'notifyOn': afterNotify,
        'notifyTime':
            '${afterHour.toString().padLeft(2, '0')}:${afterMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': nextAfterDate?.toUtc().toIso8601String(),
        'message': afterNames.isNotEmpty
            ? '어제 결제 예정이었던 구독이 있습니다.\n${afterNames.join(', ')}'
            : '',
        'fcmToken': fcmToken,
      },
    ];

    // Cloud Functions HTTP 엔드포인트로 POST
    const String serverUrl =
        'https://asia-northeast3-sheepdog-fa14d.cloudfunctions.net/saveUserNotificationSettings';

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': fcmToken, 'notifications': notifications}),
      );
      if (response.statusCode == 200) {
        print('알림 설정 서버 저장 성공');
      } else {
        print('알림 설정 서버 저장 실패: ${response.body}');
      }
    } catch (e) {
      print('알림 설정 서버 저장 중 네트워크 오류: $e');
    }
  }

  /// SharedPreferences에서 알림 설정값 읽어오기
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'beforeNotify': prefs.getBool('beforeNotify') ?? true,
      'beforeHour': prefs.getInt('beforeHour') ?? 9,
      'beforeMinute': prefs.getInt('beforeMinute') ?? 0,
      'onNotify': prefs.getBool('onNotify') ?? true,
      'onHour': prefs.getInt('onHour') ?? 9,
      'onMinute': prefs.getInt('onMinute') ?? 0,
      'afterNotify': prefs.getBool('afterNotify') ?? false,
      'afterHour': prefs.getInt('afterHour') ?? 18,
      'afterMinute': prefs.getInt('afterMinute') ?? 0,
    };
  }
}
