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

  /// FCM 토큰을 서버에 등록
  Future<void> registerFcmTokenToServer(String token) async {
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

  /// 반복 결제 주기별 미래 결제일 자동 계산
  List<DateTime> getFuturePaymentDates(
    SubscriptionService service, {
    int maxCount = 12, // iOS 알림 제한 고려
  }) {
    final List<DateTime> dates = [];
    final now = DateTime.now();
    final startDate = service.paymentStartDate ?? now;
    DateTime base = now.isBefore(startDate) ? startDate : now;

    if (service.paymentDate == null || service.paymentCycle == null)
      return dates;

    if (service.paymentCycle == PaymentCycle.monthly) {
      for (int i = 0; i < maxCount; i++) {
        final year = base.year + ((base.month + i - 1) ~/ 12);
        final month = (base.month + i - 1) % 12 + 1;
        final day = service.paymentDate!.day;
        DateTime date;
        try {
          date = DateTime(year, month, day);
        } catch (_) {
          final lastDay = DateTime(year, month + 1, 0).day;
          date = DateTime(year, month, lastDay);
        }
        if (!date.isBefore(startDate) && date.isAfter(now)) {
          dates.add(date);
        }
      }
    } else if (service.paymentCycle == PaymentCycle.weekly) {
      int added = 0;
      DateTime date = base;
      while (added < maxCount) {
        if (date.weekday == service.paymentDate!.weekday &&
            !date.isBefore(startDate) &&
            date.isAfter(now)) {
          dates.add(date);
          added++;
        }
        date = date.add(const Duration(days: 1));
      }
    } else if (service.paymentCycle == PaymentCycle.yearly) {
      for (int i = 0; i < maxCount; i++) {
        final year = base.year + i;
        final month = service.paymentDate!.month;
        final day = service.paymentDate!.day;
        DateTime date;
        try {
          date = DateTime(year, month, day);
        } catch (_) {
          final lastDay = DateTime(year, month + 1, 0).day;
          date = DateTime(year, month, lastDay);
        }
        if (!date.isBefore(startDate) && date.isAfter(now)) {
          dates.add(date);
        }
      }
    }
    return dates;
  }

  Future<void> requestSchedulePaymentNotifications({
    required List<SubscriptionService> subscriptions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    // 결제 전/당일/후 알림 설정값
    final beforeNotify = prefs.getBool('beforeNotify') ?? true;
    final beforeHour = prefs.getInt('beforeHour') ?? 9;
    final beforeMinute = prefs.getInt('beforeMinute') ?? 0;

    final onNotify = prefs.getBool('onNotify') ?? true;
    final onHour = prefs.getInt('onHour') ?? 9;
    final onMinute = prefs.getInt('onMinute') ?? 0;

    final afterNotify = prefs.getBool('afterNotify') ?? false;
    final afterDays = prefs.getInt('afterDays') ?? 2;
    final afterHour = prefs.getInt('afterHour') ?? 18;
    final afterMinute = prefs.getInt('afterMinute') ?? 0;

    // 1. 모든 구독의 미래 결제일별로 구독명을 그룹핑
    // Map<알림타입, Map<알림날짜, List<구독명>>>
    Map<String, Map<DateTime, List<String>>> grouped = {
      'before': {},
      'on': {},
      'after': {},
    };

    for (final sub in subscriptions) {
      final dates = getFuturePaymentDates(sub, maxCount: 12);
      for (final paymentDate in dates) {
        // 결제 전 알림: 하루 전
        if (beforeNotify) {
          final notifyDate = DateTime(
            paymentDate.year,
            paymentDate.month,
            paymentDate.day,
            beforeHour,
            beforeMinute,
          ).subtract(const Duration(days: 1));
          if (notifyDate.isAfter(DateTime.now())) {
            grouped['before']!.putIfAbsent(notifyDate, () => []).add(sub.name);
          }
        }
        // 결제 당일 알림
        if (onNotify) {
          final notifyDate = DateTime(
            paymentDate.year,
            paymentDate.month,
            paymentDate.day,
            onHour,
            onMinute,
          );
          if (notifyDate.isAfter(DateTime.now())) {
            grouped['on']!.putIfAbsent(notifyDate, () => []).add(sub.name);
          }
        }
        // 결제 후 알림: afterDays만큼 반복
        if (afterNotify) {
          for (int d = 1; d <= afterDays; d++) {
            final notifyDate = DateTime(
              paymentDate.year,
              paymentDate.month,
              paymentDate.day,
              afterHour,
              afterMinute,
            ).add(Duration(days: d));
            if (notifyDate.isAfter(DateTime.now())) {
              grouped['after']!.putIfAbsent(notifyDate, () => []).add(sub.name);
            }
          }
        }
      }
    }

    // 2. 그룹핑된 데이터로 알림 예약 리스트 생성
    final List<Map<String, dynamic>> scheduleList = [];

    // 결제 전 알림
    if (beforeNotify) {
      grouped['before']!.forEach((notifyDate, names) {
        scheduleList.add({
          'type': 'before',
          'notifyDate': notifyDate.toIso8601String(),
          'hour': notifyDate.hour,
          'minute': notifyDate.minute,
          'subscriptionNames': names,
          'fcmToken': fcmToken,
          'message': '내일 결제 예정인 구독이 있습니다.\n${names.join(', ')}',
        });
      });
    }

    // 결제 당일 알림
    if (onNotify) {
      grouped['on']!.forEach((notifyDate, names) {
        scheduleList.add({
          'type': 'on',
          'notifyDate': notifyDate.toIso8601String(),
          'hour': notifyDate.hour,
          'minute': notifyDate.minute,
          'subscriptionNames': names,
          'fcmToken': fcmToken,
          'message': '오늘 결제 예정인 구독이 있습니다.\n${names.join(', ')}',
        });
      });
    }

    // 결제 후 알림
    if (afterNotify) {
      grouped['after']!.forEach((notifyDate, names) {
        scheduleList.add({
          'type': 'after',
          'notifyDate': notifyDate.toIso8601String(),
          'hour': notifyDate.hour,
          'minute': notifyDate.minute,
          'subscriptionNames': names,
          'fcmToken': fcmToken,
          'message': '어제 결제 예정이었던 구독이 있습니다.\n${names.join(', ')}',
        });
      });
    }

    // 3. Firestore(또는 서버)에 예약 알림 데이터 저장
    if (scheduleList.isNotEmpty) {
      // Firestore에 직접 저장하거나, 서버/Cloud Functions에 API로 전송
      // 아래는 서버 API 예시
      const String serverUrl =
          'https://schedulepaymentnotifications-zf5sguzqdq-uc.a.run.app';
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

  Future<void> cancelSchedulePaymentNotifications({
    required String subscriptionId,
  }) async {
    // 실제 배포된 Cloud Functions URL로 교체
    const String serverUrl =
        'https://schedulepaymentnotifications-zf5sguzqdq-uc.a.run.app';
    try {
      final response = await http.delete(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'subscriptionId': subscriptionId}),
      );
      if (response.statusCode == 200) {
        print('예약 알림 취소(삭제) 서버 요청 성공');
      } else {
        print('예약 알림 취소(삭제) 서버 요청 실패: ${response.body}');
      }
    } catch (e) {
      print('예약 알림 취소(삭제) 서버 요청 중 네트워크 오류: $e');
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
      'afterDays': prefs.getInt('afterDays') ?? 2,
      'afterHour': prefs.getInt('afterHour') ?? 18,
      'afterMinute': prefs.getInt('afterMinute') ?? 0,
    };
  }
}
