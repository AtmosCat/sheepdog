import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/ui/pages/home/home_page.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

class FCMUtils {
  static const String paymentDayNotifyKey = 'paymentDayNotify';
  static const String paymentDayHourKey = 'paymentDayHour';
  static const String paymentDayMinuteKey = 'paymentDayMinute';
  static const String notificationIntroShownKey = 'notificationIntroShown';

  /// 레거시 키 호환
  static const String _legacyOnNotifyKey = 'onNotify';
  static const String _legacyOnHourKey = 'onHour';
  static const String _legacyOnMinuteKey = 'onMinute';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// FCM 초기화. [requestPermission]이 true일 때만 OS 권한을 요청한다.
  Future<String?> initFCM({bool requestPermission = false}) async {
    if (requestPermission) {
      await this.requestNotificationPermission();
    }
    return FirebaseMessaging.instance.getToken();
  }

  /// 기기 알림 권한 요청. 허용 여부 반환.
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      final result = await Permission.notification.request();
      if (result.isGranted) return true;
      if (result.isPermanentlyDenied) {
        return false;
      }
      return result.isGranted;
    }

    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }

    return false;
  }

  /// 현재 기기 알림 권한 허용 여부
  Future<bool> isNotificationPermissionGranted() async {
    if (Platform.isAndroid) {
      return Permission.notification.isGranted;
    }
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return false;
  }

  void setupInteractedMessage(BuildContext context) {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // iOS는 시스템 포그라운드 표시만 사용 (로컬 추가 시 2번 뜸)
      if (Platform.isIOS) return;

      final notification = message.notification;
      if (notification == null) return;

      // Android 포그라운드는 FCM이 자동 표시되지 않으므로 로컬 1회만 표시
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
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomePage()),
        (route) => false,
      );
    });
  }

  Future<void> registerFcmTokenToServer(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Asia/Seoul 벽시계 시각으로 nextNotifyDate 문자열 생성
  String toSeoulDateTimeIso(DateTime date, int hour, int minute) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:00+09:00';
  }

  Future<Map<String, dynamic>> getPaymentDaySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(paymentDayNotifyKey) ??
        prefs.getBool(_legacyOnNotifyKey) ??
        false;
    final hour =
        prefs.getInt(paymentDayHourKey) ?? prefs.getInt(_legacyOnHourKey) ?? 9;
    final minute = prefs.getInt(paymentDayMinuteKey) ??
        prefs.getInt(_legacyOnMinuteKey) ??
        0;
    return {
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
    };
  }

  Future<void> savePaymentDaySettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(paymentDayNotifyKey, enabled);
    await prefs.setInt(paymentDayHourKey, hour);
    await prefs.setInt(paymentDayMinuteKey, minute);
    // 레거시 키도 같이 갱신
    await prefs.setBool(_legacyOnNotifyKey, enabled);
    await prefs.setInt(_legacyOnHourKey, hour);
    await prefs.setInt(_legacyOnMinuteKey, minute);
    // 결제 전 알림 관련 레거시 값 정리
    await prefs.setBool('beforeNotify', false);
  }

  Future<void> saveUserNotificationSettings({
    required List<SubscriptionService> subscriptions,
  }) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (fcmToken == null || uid == null) return;

    final settings = await getPaymentDaySettings();
    final enabled = settings['enabled'] as bool;
    final hour = settings['hour'] as int;
    final minute = settings['minute'] as int;

    final Set<DateTime> onDatesSet = {};
    for (final sub in subscriptions) {
      final dates = getFuturePaymentDates(sub);
      for (final date in dates) {
        onDatesSet.add(DateTime(date.year, date.month, date.day));
      }
    }
    final List<DateTime> futureOnNotifyDates = onDatesSet.toList()..sort();
    final DateTime? nextOnDate =
        futureOnNotifyDates.isNotEmpty ? futureOnNotifyDates.first : null;

    final Map<String, dynamic> dataToSave = {
      'fcmToken': fcmToken,
      'updatedAt': FieldValue.serverTimestamp(),
      'futureOnNotifyDates':
          futureOnNotifyDates.map((d) => d.toIso8601String()).toList(),
      // 결제 전 알림 제거
      'futureBeforeNotifyDates': FieldValue.delete(),
      'before': FieldValue.delete(),
    };

    if (nextOnDate != null) {
      dataToSave['on'] = {
        'notifyOn': enabled,
        'notifyTime':
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        'nextNotifyDate': toSeoulDateTimeIso(nextOnDate, hour, minute),
      };
    } else {
      dataToSave['on'] = {
        'notifyOn': enabled,
        'notifyTime':
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        'nextNotifyDate': null,
      };
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    await userDoc.set(dataToSave, SetOptions(merge: true));
  }

  /// 결제일 알림 ON/OFF. ON 시 권한이 없으면 재요청한다.
  /// 반환: 최종 활성화 여부
  Future<bool> setPaymentDayNotifyEnabled(bool enabled) async {
    if (enabled) {
      final granted = await requestNotificationPermission();
      if (!granted) {
        // 영구 거절 등 → 설정 앱으로 유도할 수 있도록 false 유지
        await savePaymentDaySettings(
          enabled: false,
          hour: (await getPaymentDaySettings())['hour'] as int,
          minute: (await getPaymentDaySettings())['minute'] as int,
        );
        await _syncNotifyOnToFirestore(false);
        return false;
      }
    }

    final settings = await getPaymentDaySettings();
    await savePaymentDaySettings(
      enabled: enabled,
      hour: settings['hour'] as int,
      minute: settings['minute'] as int,
    );
    await _syncNotifyOnToFirestore(enabled);
    return enabled;
  }

  Future<void> _syncNotifyOnToFirestore(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'on': {'notifyOn': enabled},
      'before': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resetNotificationIfNoSubscriptions(List subscriptions) async {
    if (subscriptions.isNotEmpty) return;

    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'on': {
        'notifyOn': false,
        'notifyTime': null,
        'nextNotifyDate': null,
      },
      'before': FieldValue.delete(),
      'futureOnNotifyDates': <String>[],
      'futureBeforeNotifyDates': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 테스트 발송: Firestore에 토큰을 반영한 뒤, 서버가 Firestore 기준으로 FCM 발송.
  /// 로컬 알림은 사용하지 않는다.
  Future<void> sendTestPaymentDayNotification() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      throw Exception('FCM 토큰을 가져올 수 없습니다. 알림 권한을 확인해 주세요.');
    }

    // 실제 스케줄러와 동일하게 Firestore users/{uid} 기준
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final response = await http
        .post(
          Uri.parse(
            'https://asia-northeast3-sheepdog-fa14d.cloudfunctions.net/sendTestNotification',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uid': uid}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'FCM 테스트 발송 실패 (${response.statusCode}): ${response.body}',
      );
    }
  }
}
