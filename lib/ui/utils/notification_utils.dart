// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sheepdog/data/model/subscription_service.dart';
// import 'package:timezone/timezone.dart' as tz;

// class NotificationsUtils {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   Future<void> setDefaultNotificationPrefsIfNeeded() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (!prefs.containsKey('paymentDayNotify')) {
//       await prefs.setBool('paymentDayNotify', true);
//       await prefs.setInt('paymentDayBefore', 3);
//       await prefs.setInt('paymentDayHour', 9);
//       await prefs.setInt('paymentDayMinute', 0);
//     }
//     if (!prefs.containsKey('paymentConfirmNotify')) {
//       await prefs.setBool('paymentConfirmNotify', true);
//       await prefs.setInt('paymentConfirmAfter', 1);
//       await prefs.setInt('paymentConfirmHour', 9);
//       await prefs.setInt('paymentConfirmMinute', 0);
//     }
//   }

//   Future<void> schedulePaymentNotification({
//     required DateTime scheduledTime,
//     required String title,
//     required String body,
//     required int notificationId,
//   }) async {
//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       notificationId,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledTime, tz.local),
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'payment_channel',
//           '결제 알림',
//           channelDescription: '구독 결제 알림',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // 필수!
//       matchDateTimeComponents: DateTimeComponents.dateAndTime,
//     );
//   }

//   List<DateTime> getFuturePaymentDates(
//     SubscriptionService service, {
//     int maxCount = 12, // iOS 제한 고려 (64개 이하)
//   }) {
//     final List<DateTime> dates = [];
//     final now = DateTime.now();
//     final startDate = service.paymentStartDate ?? now;
//     DateTime base = now.isBefore(startDate) ? startDate : now;

//     if (service.paymentDate == null || service.paymentCycle == null)
//       return dates;

//     if (service.paymentCycle == PaymentCycle.monthly) {
//       for (int i = 0; i < maxCount; i++) {
//         final year = base.year + ((base.month + i - 1) ~/ 12);
//         final month = (base.month + i - 1) % 12 + 1;
//         final day = service.paymentDate!.day;
//         DateTime date;
//         try {
//           date = DateTime(year, month, day);
//         } catch (_) {
//           final lastDay = DateTime(year, month + 1, 0).day;
//           date = DateTime(year, month, lastDay);
//         }
//         if (!date.isBefore(startDate) && date.isAfter(now)) {
//           dates.add(date);
//         }
//       }
//     } else if (service.paymentCycle == PaymentCycle.weekly) {
//       int added = 0;
//       DateTime date = base;
//       while (added < maxCount) {
//         if (date.weekday == service.paymentDate!.weekday &&
//             !date.isBefore(startDate) &&
//             date.isAfter(now)) {
//           dates.add(date);
//           added++;
//         }
//         date = date.add(const Duration(days: 1));
//       }
//     } else if (service.paymentCycle == PaymentCycle.yearly) {
//       for (int i = 0; i < maxCount; i++) {
//         final year = base.year + i;
//         final month = service.paymentDate!.month;
//         final day = service.paymentDate!.day;
//         DateTime date;
//         try {
//           date = DateTime(year, month, day);
//         } catch (_) {
//           final lastDay = DateTime(year, month + 1, 0).day;
//           date = DateTime(year, month, lastDay);
//         }
//         if (!date.isBefore(startDate) && date.isAfter(now)) {
//           dates.add(date);
//         }
//       }
//     }
//     return dates;
//   }

//   Future<void> cancelAllScheduledNotificationsForService(
//     SubscriptionService service,
//   ) async {
//     for (int i = 0; i < 20; i++) {
//       // 서비스별 최대 20개씩 예약한다고 가정
//       await flutterLocalNotificationsPlugin.cancel(service.hashCode + i);
//       await flutterLocalNotificationsPlugin.cancel(
//         service.hashCode + 100000 + i,
//       );
//     }
//   }

//   Future<void> scheduleAllPaymentNotificationsForService(
//     SubscriptionService service, {
//     required bool paymentDayNotify,
//     required int paymentDayBefore,
//     required int paymentDayHour,
//     required int paymentDayMinute,
//     required bool paymentConfirmNotify,
//     required int paymentConfirmAfter,
//     required int paymentConfirmHour,
//     required int paymentConfirmMinute,
//   }) async {
//     await cancelAllScheduledNotificationsForService(service);
//     final dates = getFuturePaymentDates(service, maxCount: 10); // iOS 제한 고려
//     for (int idx = 0; idx < dates.length; idx++) {
//       final paymentDate = dates[idx];

//       // 결제일 전 알림
//       if (paymentDayNotify) {
//         final paymentDay = DateTime(
//           paymentDate.year,
//           paymentDate.month,
//           paymentDate.day,
//           paymentDayHour,
//           paymentDayMinute,
//         ).subtract(Duration(days: paymentDayBefore));
//         if (paymentDay.isAfter(DateTime.now())) {
//           await schedulePaymentNotification(
//             scheduledTime: paymentDay,
//             title: '구독 결제 예정',
//             body: '${service.name} 결제가 $paymentDayBefore일 후 예정입니다.',
//             notificationId: service.hashCode + idx,
//           );
//         }
//       }

//       // 결제일 후 알림
//       if (paymentConfirmNotify) {
//         final confirmDay = DateTime(
//           paymentDate.year,
//           paymentDate.month,
//           paymentDate.day,
//           paymentConfirmHour,
//           paymentConfirmMinute,
//         ).add(Duration(days: paymentConfirmAfter));
//         if (confirmDay.isAfter(DateTime.now())) {
//           await schedulePaymentNotification(
//             scheduledTime: confirmDay,
//             title: '구독 결제 확인',
//             body: '${service.name} 결제 후 $paymentConfirmAfter일이 지났습니다.',
//             notificationId: service.hashCode + 100000 + idx,
//           );
//         }
//       }
//     }
//   }
// }
