import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/utils/fcm_utils.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _enabled = false;
  int _hour = 9;
  int _minute = 0;
  bool _loading = true;

  final _fcm = FCMUtils();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final settings = await _fcm.getPaymentDaySettings();
    if (!mounted) return;
    setState(() {
      _enabled = settings['enabled'] as bool? ?? false;
      _hour = settings['hour'] as int? ?? 9;
      _minute = settings['minute'] as int? ?? 0;
      _loading = false;
    });
  }

  Future<void> _syncSchedule() async {
    final subscriptions =
        await SubscriptionServiceRepository().getAllServices();
    await _fcm.saveUserNotificationSettings(subscriptions: subscriptions);
  }

  Future<void> _onToggle(bool value) async {
    if (value) {
      final enabled = await _fcm.setPaymentDayNotifyEnabled(true);
      if (!mounted) return;
      setState(() => _enabled = enabled);
      if (!enabled) {
        SnackbarUtil.showToastMessage('알림 권한이 필요합니다. 설정에서 허용해 주세요.');
        await openAppSettings();
        return;
      }
      await _syncSchedule();
      SnackbarUtil.showToastMessage('결제일 알림이 켜졌습니다.');
    } else {
      await _fcm.setPaymentDayNotifyEnabled(false);
      if (!mounted) return;
      setState(() => _enabled = false);
      await _syncSchedule();
      SnackbarUtil.showToastMessage('결제일 알림이 꺼졌습니다.');
    }
  }

  Future<void> _saveTimeAndSync() async {
    await _fcm.savePaymentDaySettings(
      enabled: _enabled,
      hour: _hour,
      minute: _minute,
    );
    await _syncSchedule();
    SnackbarUtil.showToastMessage('알림 설정이 저장되었습니다.');
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h시 $m분';
  }

  Future<void> _showTimeDialog() async {
    int tempHour = _hour;
    int tempMinute = _minute;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 400),
              decoration: BoxDecoration(
                color: AppColor.containerWhite.of(context),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '결제일 알림 설정',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '결제가 발생하는 날 알림을 보내드려요.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '알림 전송 시각',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 90,
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: tempHour,
                            ),
                            itemExtent: 32,
                            useMagnifier: true,
                            magnification: 1.08,
                            squeeze: 1.1,
                            onSelectedItemChanged: (idx) => tempHour = idx,
                            children: List<Widget>.generate(24, (idx) {
                              return Center(
                                child: Text(
                                  '${idx.toString().padLeft(2, '0')}시',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: tempMinute ~/ 10,
                            ),
                            itemExtent: 32,
                            useMagnifier: true,
                            magnification: 1.08,
                            squeeze: 1.1,
                            onSelectedItemChanged: (idx) {
                              tempMinute = idx * 10;
                            },
                            children: List<Widget>.generate(6, (idx) {
                              final minute = idx * 10;
                              return Center(
                                child: Text(
                                  '${minute.toString().padLeft(2, '0')}분',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: AppColor.mainYellow.of(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () async {
                          setState(() {
                            _hour = tempHour;
                            _minute = tempMinute;
                          });
                          await _saveTimeAndSync();
                          if (mounted) Navigator.pop(context);
                        },
                        child: Text(
                          '확인',
                          style: TextStyle(
                            color: AppColor.deepBlack.of(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        centerTitle: true,
        backgroundColor: AppColor.containerWhite.of(context),
        foregroundColor: AppColor.deepBlack.of(context),
        elevation: 0,
      ),
      backgroundColor: AppColor.containerWhite.of(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '결제일 알림',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColor.deepBlack.of(context),
                        ),
                      ),
                      Switch(
                        value: _enabled,
                        onChanged: _onToggle,
                        activeColor: AppColor.mainYellow.of(context),
                        inactiveThumbColor: AppColor.gray10.of(context),
                        inactiveTrackColor: AppColor.gray20.of(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showTimeDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _enabled
                            ? AppColor.mainYellowLight3.of(context)
                            : AppColor.containerLightGray30.of(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '결제 당일, ${_formatTime(_hour, _minute)}',
                              style: TextStyle(
                                color: _enabled
                                    ? AppColor.mainYellow.of(context)
                                    : AppColor.lightGray20.of(context),
                                fontWeight: _enabled
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: _enabled
                                ? AppColor.mainYellow.of(context)
                                : AppColor.gray30.of(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '결제가 발생하는 날, 설정한 시각에 알림을 보내드려요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColor.gray30.of(context),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
