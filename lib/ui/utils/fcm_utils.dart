import 'package:cloud_firestore/cloud_firestore.dart';
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

    // [수정] messageId가 있으면 고유값으로 활용, 없으면 title/body/receivedAt 조합
    final receivedAt = DateTime.now().toIso8601String();
    final notificationData = {
      'title': notification.title ?? '',
      'body': notification.body ?? '',
      'receivedAt': receivedAt,
      'read': false,
      // 'messageId': message.messageId, // 필요시 추가
    };

    // [수정] 저장 전 중복 체크
    final db = await LocalNotificationRepository().database;
    final existing = await db.query(
      'notifications',
      where: 'title = ? AND body = ? AND receivedAt = ?',
      whereArgs: [
        notificationData['title'],
        notificationData['body'],
        notificationData['receivedAt'],
      ],
    );
    if (existing.isEmpty) {
      await LocalNotificationRepository().insertNotification(notificationData);
    } else {
      print('[알림] saveNotificationHistory: 중복 저장 차단');
    }
  }

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

      if (beforeNotify && paymentDate.difference(today).inDays == 1) {
        hasBefore = true;
      }
      if (onNotify && paymentDate.difference(today).inDays == 0) {
        hasOn = true;
      }
      if (afterNotify && paymentDate.difference(today).inDays == -1) {
        hasAfter = true;
      }
    }

    Future<DateTime?> getPrevNextNotifyDate(String type) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('user_notifications')
            .doc('${fcmToken}_$type')
            .get();
        if (doc.exists && doc.data()?['nextNotifyDate'] != null) {
          final nextDateStr = doc.data()!['nextNotifyDate'];
          print('[알림] Firestore에서 읽은 nextNotifyDate($type): $nextDateStr');
          return DateTime.parse(nextDateStr);
        }
        print('[알림] Firestore에 nextNotifyDate($type) 없음');
        return null;
      } catch (e) {
        print('[알림] Firestore에서 nextNotifyDate($type) 읽기 실패: $e');
        return null;
      }
    }

    final notifications = <Map<String, dynamic>>[];

    if (hasBefore) {
      DateTime? prevNextDate = await getPrevNextNotifyDate('before');
      DateTime baseDate;
      if (prevNextDate != null) {
        baseDate = DateTime(
          prevNextDate.year,
          prevNextDate.month,
          prevNextDate.day,
          beforeHour,
          beforeMinute,
        );
      } else {
        final nowDate = DateTime(now.year, now.month, now.day);
        baseDate = DateTime(
          nowDate.year,
          nowDate.month,
          nowDate.day,
          beforeHour,
          beforeMinute,
        );
      }
      notifications.add({
        'type': 'before',
        'notifyOn': true,
        'notifyTime':
            '${beforeHour.toString().padLeft(2, '0')}:${beforeMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': baseDate.toUtc().toIso8601String(),
        'fcmToken': fcmToken,
      });
    }

    if (hasOn) {
      DateTime? prevNextDate = await getPrevNextNotifyDate('on');
      DateTime baseDate;
      if (prevNextDate != null) {
        baseDate = DateTime(
          prevNextDate.year,
          prevNextDate.month,
          prevNextDate.day,
          onHour,
          onMinute,
        );
      } else {
        final nowDate = DateTime(now.year, now.month, now.day);
        baseDate = DateTime(
          nowDate.year,
          nowDate.month,
          nowDate.day,
          onHour,
          onMinute,
        );
      }
      notifications.add({
        'type': 'on',
        'notifyOn': true,
        'notifyTime':
            '${onHour.toString().padLeft(2, '0')}:${onMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': baseDate.toUtc().toIso8601String(),
        'fcmToken': fcmToken,
      });
    }

    if (hasAfter) {
      DateTime? prevNextDate = await getPrevNextNotifyDate('after');
      DateTime baseDate;
      if (prevNextDate != null) {
        baseDate = DateTime(
          prevNextDate.year,
          prevNextDate.month,
          prevNextDate.day,
          afterHour,
          afterMinute,
        );
      } else {
        final nowDate = DateTime(now.year, now.month, now.day);
        baseDate = DateTime(
          nowDate.year,
          nowDate.month,
          nowDate.day,
          afterHour,
          afterMinute,
        );
      }
      notifications.add({
        'type': 'after',
        'notifyOn': true,
        'notifyTime':
            '${afterHour.toString().padLeft(2, '0')}:${afterMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': baseDate.toUtc().toIso8601String(),
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
