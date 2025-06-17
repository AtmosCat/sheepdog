import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // print('FCM Token: $token');
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

      // // 1. 알림 내역 저장
      // await saveNotificationHistory(message);

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
              icon: 'icon10',
            ),
            iOS: DarwinNotificationDetails(), // iOS도 알림 표시
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
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

  // Future<void> saveNotificationHistory(RemoteMessage message) async {
  //   final notification = message.notification;
  //   if (notification == null) return;

  //   // [수정] messageId 또는 data['type']+title+body+nextNotifyDate 등 고유값 활용
  //   final type = message.data['type'] ?? '';
  //   final nextNotifyDate = message.data['nextNotifyDate'] ?? '';
  //   final messageId = message.messageId ?? '';
  //   final notificationData = {
  //     'title': notification.title ?? '',
  //     'body': notification.body ?? '',
  //     'type': type,
  //     'nextNotifyDate': nextNotifyDate,
  //     'messageId': messageId,
  //     'receivedAt': DateTime.now().toIso8601String(),
  //     'read': false,
  //   };

  //   final db = await LocalNotificationRepository().database;
  //   // [수정] messageId가 있으면 그것으로, 없으면 type+title+body+nextNotifyDate로 중복 체크
  //   String where;
  //   List whereArgs;
  //   if (messageId.isNotEmpty) {
  //     where = 'messageId = ?';
  //     whereArgs = [messageId];
  //   } else {
  //     where = 'type = ? AND title = ? AND body = ? AND nextNotifyDate = ?';
  //     whereArgs = [
  //       type,
  //       notification.title ?? '',
  //       notification.body ?? '',
  //       nextNotifyDate,
  //     ];
  //   }
  //   final existing = await db.query(
  //     'notifications',
  //     where: where,
  //     whereArgs: whereArgs,
  //   );
  //   if (existing.isEmpty) {
  //     await LocalNotificationRepository().insertNotification(notificationData);
  //   } else {
  //     print('[알림] saveNotificationHistory: 중복 저장 차단');
  //   }
  // }

  Future<void> saveUserNotificationSettings({
    required List<SubscriptionService> subscriptions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (fcmToken == null || uid == null) return;

    final beforeNotify = prefs.getBool('beforeNotify') ?? true;
    final beforeHour = prefs.getInt('beforeHour') ?? 9;
    final beforeMinute = prefs.getInt('beforeMinute') ?? 0;
    final onNotify = prefs.getBool('onNotify') ?? true;
    final onHour = prefs.getInt('onHour') ?? 9;
    final onMinute = prefs.getInt('onMinute') ?? 0;

    // 결제 당일 알림용: 모든 구독의 미래 결제일(3년치) 중복 없이 모으기
    final Set<DateTime> onDatesSet = {};
    for (final sub in subscriptions) {
      final dates = getFuturePaymentDates(sub);
      for (final date in dates) {
        onDatesSet.add(DateTime(date.year, date.month, date.day));
      }
    }
    final List<DateTime> futureOnNotifyDates = onDatesSet.toList()..sort();

    // 결제 전 알림용: 모든 구독의 결제 전날(3년치) 중복 없이 모으기
    final Set<DateTime> beforeDatesSet = {};
    for (final sub in subscriptions) {
      final dates = getFutureBeforeNotifyDates(sub);
      for (final date in dates) {
        beforeDatesSet.add(DateTime(date.year, date.month, date.day));
      }
    }
    final List<DateTime> futureBeforeNotifyDates = beforeDatesSet.toList()
      ..sort();

    // 가장 가까운 결제 전/당일 알림일 계산
    DateTime? nextBeforeDate = futureBeforeNotifyDates.isNotEmpty
        ? futureBeforeNotifyDates.first
        : null;
    DateTime? nextOnDate = futureOnNotifyDates.isNotEmpty
        ? futureOnNotifyDates.first
        : null;

    // Firestore users 컬렉션의 uid 문서에 저장할 데이터 구조
    final Map<String, dynamic> dataToSave = {
      'fcmToken': fcmToken,
      'updatedAt': FieldValue.serverTimestamp(),
      // futureOnNotifyDates와 futureBeforeNotifyDates를 ISO8601 문자열 배열로 저장
      'futureOnNotifyDates': futureOnNotifyDates
          .map((d) => d.toIso8601String())
          .toList(),
      'futureBeforeNotifyDates': futureBeforeNotifyDates
          .map((d) => d.toIso8601String())
          .toList(),
    };

    if (nextBeforeDate != null) {
      dataToSave['before'] = {
        'notifyOn': beforeNotify,
        'notifyTime':
            '${beforeHour.toString().padLeft(2, '0')}:${beforeMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': DateTime(
          nextBeforeDate.year,
          nextBeforeDate.month,
          nextBeforeDate.day,
          beforeHour,
          beforeMinute,
        ).toUtc().toIso8601String(),
      };
    } else {
      dataToSave['before'] = FieldValue.delete();
    }

    if (nextOnDate != null) {
      dataToSave['on'] = {
        'notifyOn': onNotify,
        'notifyTime':
            '${onHour.toString().padLeft(2, '0')}:${onMinute.toString().padLeft(2, '0')}',
        'nextNotifyDate': DateTime(
          nextOnDate.year,
          nextOnDate.month,
          nextOnDate.day,
          onHour,
          onMinute,
        ).toUtc().toIso8601String(),
      };
    } else {
      dataToSave['on'] = FieldValue.delete();
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    await userDoc.set(dataToSave, SetOptions(merge: true));
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
    };
  }

  Future<void> setNotificationEnabled({
    required bool beforeEnabled,
    required bool onEnabled,
  }) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    await ref.set({
      'before': {'notifyOn': beforeEnabled},
      'on': {'notifyOn': onEnabled},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 구독이 하나도 없으면 알림 관련 필드를 null로 리셋
  Future<void> resetNotificationIfNoSubscriptions(List subscriptions) async {
    if (subscriptions.isNotEmpty) return; // 구독이 남아 있으면 아무것도 하지 않음

    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    await userDoc.update({
      'before': {'notifyOn': false, 'notifyTime': null, 'nextNotifyDate': null},
      'on': {'notifyOn': false, 'notifyTime': null, 'nextNotifyDate': null},
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
