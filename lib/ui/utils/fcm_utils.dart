import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sheepdog/data/model/subscription_service.dart';

class FCMUtils {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// FCM 권한 요청 및 토큰 획득
  Future<String?> initFCM() async {
    await FirebaseMessaging.instance.requestPermission();
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
    // 서버에 토큰 등록(로그인 없는 경우에도 필요)
    if (token != null) {
      await registerFcmTokenToServer(token);
    }
    return token;
  }

  /// 포그라운드 알림 표시 및 클릭 핸들러 등록
  void setupInteractedMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
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
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // TODO: 알림 클릭 시 원하는 페이지로 이동 등 처리
    });
  }

  /// FCM 토큰을 서버에 등록 (로그인 없는 앱의 경우에도 기기 식별용)
  Future<void> registerFcmTokenToServer(String token) async {
    // 서버 API 주소에 맞게 수정
    const String serverUrl = 'https://your-server.com/api/register_fcm_token';
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fcm_token': token}),
    );
    if (response.statusCode == 200) {
      print('FCM 토큰 서버 등록 성공');
    } else {
      print('FCM 토큰 서버 등록 실패: ${response.body}');
    }
  }

  /// 결제일 알림 예약 요청 (서버에 예약 요청)
  Future<void> requestSchedulePaymentNotifications({
    required List<SubscriptionService> subscriptions, // 내부 DB에서 불러온 구독 리스트
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 결제일 전 알림 ON/OFF 및 설정값
    final paymentDayNotify = prefs.getBool('paymentDayNotify') ?? true;
    final paymentDayBefore = prefs.getInt('paymentDayBefore') ?? 3;
    final paymentDayHour = prefs.getInt('paymentDayHour') ?? 9;
    final paymentDayMinute = prefs.getInt('paymentDayMinute') ?? 0;

    // 결제일 후 알림 ON/OFF 및 설정값
    final paymentConfirmNotify = prefs.getBool('paymentConfirmNotify') ?? false;
    final paymentConfirmAfter = prefs.getInt('paymentConfirmAfter') ?? 2;
    final paymentConfirmHour = prefs.getInt('paymentConfirmHour') ?? 18;
    final paymentConfirmMinute = prefs.getInt('paymentConfirmMinute') ?? 0;

    // 모든 구독의 결제일 집계
    final Set<DateTime> allPaymentDates = {};
    for (final sub in subscriptions) {
      if (sub.paymentDate != null) {
        allPaymentDates.add(
          DateTime(
            sub.paymentDate!.year,
            sub.paymentDate!.month,
            sub.paymentDate!.day,
          ),
        );
      }
    }

    final List<Map<String, dynamic>> scheduleList = [];

    // 결제일 전 알림 예약 (ON일 때만)
    if (paymentDayNotify) {
      for (final paymentDate in allPaymentDates) {
        for (int d = paymentDayBefore; d >= 0; d--) {
          final notifyDate = paymentDate.subtract(Duration(days: d));
          if (notifyDate.isAfter(DateTime.now())) {
            scheduleList.add({
              'type': 'before',
              'notifyDate': notifyDate.toIso8601String(),
              'hour': paymentDayHour,
              'minute': paymentDayMinute,
              'message': '결제일이 ${d == 0 ? "오늘" : "$d일 남았습니다."}',
            });
          }
        }
      }
    }

    // 결제일 후 알림 예약 (ON일 때만)
    if (paymentConfirmNotify) {
      for (final paymentDate in allPaymentDates) {
        for (int d = 1; d <= paymentConfirmAfter; d++) {
          final notifyDate = paymentDate.add(Duration(days: d));
          if (notifyDate.isAfter(DateTime.now())) {
            scheduleList.add({
              'type': 'after',
              'notifyDate': notifyDate.toIso8601String(),
              'hour': paymentConfirmHour,
              'minute': paymentConfirmMinute,
              'message': '결제일로부터 $d일이 지났습니다.',
            });
          }
        }
      }
    }

    // 알림이 하나라도 있을 때만 서버에 예약 요청
    if (scheduleList.isNotEmpty) {
      const String serverUrl =
          'https://your-server.com/api/schedule_payment_notifications';
      try {
        final response = await http.post(
          Uri.parse(serverUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'schedules': scheduleList}),
        );
        if (response.statusCode == 200) {
          print('알림 예약 서버 요청 성공');
        } else {
          print('알림 예약 서버 요청 실패: ${response.body}');
        }
      } catch (e) {
        print('알림 예약 서버 요청 중 네트워크 오류: $e');
      }
    } else {
      print('알림이 꺼져 있거나 예약할 알림이 없습니다.');
    }
  }

  /// SharedPreferences에서 알림 설정값 읽어오기
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'paymentDayNotify': prefs.getBool('paymentDayNotify') ?? true,
      'paymentDayBefore': prefs.getInt('paymentDayBefore') ?? 3,
      'paymentDayHour': prefs.getInt('paymentDayHour') ?? 9,
      'paymentDayMinute': prefs.getInt('paymentDayMinute') ?? 0,
      'paymentConfirmNotify': prefs.getBool('paymentConfirmNotify') ?? false,
      'paymentConfirmAfter': prefs.getInt('paymentConfirmAfter') ?? 2,
      'paymentConfirmHour': prefs.getInt('paymentConfirmHour') ?? 18,
      'paymentConfirmMinute': prefs.getInt('paymentConfirmMinute') ?? 0,
    };
  }
}
