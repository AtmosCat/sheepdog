import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/utils/fcm_utils.dart';

/// 첫 실행 시 알림 동의 안내 화면
class NotificationIntroPage extends StatefulWidget {
  final VoidCallback onFinished;

  const NotificationIntroPage({
    Key? key,
    required this.onFinished,
  }) : super(key: key);

  @override
  State<NotificationIntroPage> createState() => _NotificationIntroPageState();
}

class _NotificationIntroPageState extends State<NotificationIntroPage> {
  bool _busy = false;

  Future<void> _finish({required bool agree}) async {
    if (_busy) return;
    setState(() => _busy = true);

    final fcm = FCMUtils();
    final prefs = await SharedPreferences.getInstance();

    try {
      if (agree) {
        final granted = await fcm.requestNotificationPermission();
        await fcm.savePaymentDaySettings(
          enabled: granted,
          hour: 9,
          minute: 0,
        );
        if (granted) {
          await fcm.initFCM(requestPermission: false);
          final subscriptions =
              await SubscriptionServiceRepository().getAllServices();
          await fcm.saveUserNotificationSettings(
            subscriptions: subscriptions,
          );
        }
      } else {
        await fcm.savePaymentDaySettings(
          enabled: false,
          hour: 9,
          minute: 0,
        );
        await fcm.setPaymentDayNotifyEnabled(false);
      }
    } catch (_) {
      // 안내 완료는 막지 않음
    }

    await prefs.setBool(FCMUtils.notificationIntroShownKey, true);
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.containerWhite.of(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 56,
                color: AppColor.mainYellow.of(context),
              ),
              const SizedBox(height: 28),
              Text(
                '결제일 알림을\n받아보시겠어요?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: AppColor.deepBlack.of(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '결제일이 되면 알려드려서\n놓치지 않고 관리할 수 있어요.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColor.gray20.of(context),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _finish(agree: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.mainYellow.of(context),
                    foregroundColor: AppColor.deepBlack.of(context),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '알림 받기',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _busy ? null : () => _finish(agree: false),
                  child: Text(
                    '나중에 하기',
                    style: TextStyle(
                      color: AppColor.gray30.of(context),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
