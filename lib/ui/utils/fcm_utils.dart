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

  /// 구독 전체를 정확히 순회하여, 결제 전/당일/후 알림이 하나라도 있으면 각각의 알림을 예약
  Future<void> saveUserNotificationSettings({
    required List<SubscriptionService> subscriptions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    final beforeNotify = prefs.getBool('beforeNotify') ?? true;
    final beforeHour = prefs.getInt('beforeHour') ?? 9;
    final beforeMinute = prefs.getInt('beforeMinute') ?? 0;
    final onNotify = prefs.getBool('onNotify') ?? true;
    final onHour = prefs.getInt('onHour') ?? 9;
    final onMinute = prefs.getInt('onMinute') ?? 0;
    final afterNotify = prefs.getBool('afterNotify') ?? false;
    final afterHour = prefs.getInt('afterHour') ?? 18;
    final afterMinute = prefs.getInt('afterMinute') ?? 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool hasBefore = false;
    bool hasOn = false;
    bool hasAfter = false;

    for (final sub in subscriptions) {
      final dates = getFuturePaymentDates(sub, maxCount: 1);
      if (dates.isEmpty) continue;
      final paymentDate = dates.first;

      // 결제 전: 내일 결제 예정인 구독
      if (beforeNotify && paymentDate.difference(today).inDays == 1) {
        hasBefore = true;
      }
      // 결제 당일: 오늘 결제 예정인 구독
      if (onNotify && paymentDate.difference(today).inDays == 0) {
        hasOn = true;
      }
      // 결제 후: 어제 결제 예정이었던 구독
      if (afterNotify && paymentDate.difference(today).inDays == -1) {
        hasAfter = true;
      }
    }

    final notifications = <Map<String, dynamic>>[];

    if (hasBefore) {
      final beforeDate = DateTime(
        today.year,
        today.month,
        today.day,
        beforeHour,
        beforeMinute,
      );
      notifications.add({
        'type': 'before',
        'notifyOn': true,
        'notifyTime':
            '${beforeHour.toString().padLeft(2, '0')}:${beforeMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': beforeDate.toUtc().toIso8601String(),
        'fcmToken': fcmToken,
      });
    }
    if (hasOn) {
      final onDate = DateTime(
        today.year,
        today.month,
        today.day,
        onHour,
        onMinute,
      );
      notifications.add({
        'type': 'on',
        'notifyOn': true,
        'notifyTime':
            '${onHour.toString().padLeft(2, '0')}:${onMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': onDate.toUtc().toIso8601String(),
        'fcmToken': fcmToken,
      });
    }
    if (hasAfter) {
      final afterDate = DateTime(
        today.year,
        today.month,
        today.day,
        afterHour,
        afterMinute,
      );
      notifications.add({
        'type': 'after',
        'notifyOn': true,
        'notifyTime':
            '${afterHour.toString().padLeft(2, '0')}:${afterMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': afterDate.toUtc().toIso8601String(),
        'fcmToken': fcmToken,
      });
    }

    // 서버로 전송
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
