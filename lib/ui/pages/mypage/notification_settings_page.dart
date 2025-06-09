import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // 결제일 알림
  bool _paymentDayNotify = true;
  int _paymentDayBefore = 3;
  int _paymentDayHour = 9;
  int _paymentDayMinute = 0;

  // 결제 확인 알림
  bool _paymentConfirmNotify = false;
  int _paymentConfirmAfter = 2;
  int _paymentConfirmHour = 18;
  int _paymentConfirmMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _paymentDayNotify = prefs.getBool('paymentDayNotify') ?? true;
      _paymentDayBefore = prefs.getInt('paymentDayBefore') ?? 3;
      _paymentDayHour = prefs.getInt('paymentDayHour') ?? 9;
      _paymentDayMinute = prefs.getInt('paymentDayMinute') ?? 0;

      _paymentConfirmNotify = prefs.getBool('paymentConfirmNotify') ?? false;
      _paymentConfirmAfter = prefs.getInt('paymentConfirmAfter') ?? 2;
      _paymentConfirmHour = prefs.getInt('paymentConfirmHour') ?? 18;
      _paymentConfirmMinute = prefs.getInt('paymentConfirmMinute') ?? 0;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('paymentDayNotify', _paymentDayNotify);
    await prefs.setInt('paymentDayBefore', _paymentDayBefore);
    await prefs.setInt('paymentDayHour', _paymentDayHour);
    await prefs.setInt('paymentDayMinute', _paymentDayMinute);

    await prefs.setBool('paymentConfirmNotify', _paymentConfirmNotify);
    await prefs.setInt('paymentConfirmAfter', _paymentConfirmAfter);
    await prefs.setInt('paymentConfirmHour', _paymentConfirmHour);
    await prefs.setInt('paymentConfirmMinute', _paymentConfirmMinute);
  }

  // 시간 텍스트 포맷
  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h시 $m분';
  }

  Future<void> _showSettingDialog({
    required String title,
    required int dayValue,
    required bool isBefore,
    required int hourValue,
    required int minuteValue,
    required ValueChanged<int> onDayChanged,
    required ValueChanged<int> onHourChanged,
    required ValueChanged<int> onMinuteChanged,
  }) async {
    int tempDay = dayValue;
    int tempHour = hourValue;
    int tempMinute = minuteValue;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 410),
              decoration: BoxDecoration(
                color: AppColor.containerWhite.of(context),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColor.deepBlack.of(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '알림 시작일',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(
                    height: 90,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: tempDay - 1,
                      ),
                      itemExtent: 32,
                      useMagnifier: true,
                      magnification: 1.08,
                      squeeze: 1.1,
                      onSelectedItemChanged: (idx) {
                        tempDay = idx + 1;
                      },
                      children: List<Widget>.generate(9, (idx) {
                        // isBefore가 true면 "결제 ?일 전부터", false면 "결제 ?일 후까지"
                        final text = isBefore
                            ? '결제 ${idx + 1}일 전부터'
                            : '결제 ${idx + 1}일 후까지';
                        return Center(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColor.deepBlack.of(context),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '알림 전송 시각',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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
                            onSelectedItemChanged: (idx) {
                              tempHour = idx;
                            },
                            children: List<Widget>.generate(24, (idx) {
                              return Center(
                                child: Text(
                                  '${idx.toString().padLeft(2, '0')}시',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColor.deepBlack.of(context),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: tempMinute,
                            ),
                            itemExtent: 32,
                            useMagnifier: true,
                            magnification: 1.08,
                            squeeze: 1.1,
                            onSelectedItemChanged: (idx) {
                              tempMinute = idx;
                            },
                            children: List<Widget>.generate(60, (idx) {
                              return Center(
                                child: Text(
                                  '${idx.toString().padLeft(2, '0')}분',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColor.deepBlack.of(context),
                                  ),
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
                          onDayChanged(tempDay);
                          onHourChanged(tempHour);
                          onMinuteChanged(tempMinute);
                          await _savePrefs();
                          SnackbarUtil.showToastMessage("알림 설정이 저장되었습니다.");
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

  Widget _buildSection({
    required String title,
    required bool enabled,
    required VoidCallback onToggle,
    required VoidCallback onSectionTap,
    required String sectionText,
    required Color sectionBg,
    required Color textColor,
    required Color chevronColor,
    required bool switchValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColor.deepBlack.of(context),
              ),
            ),
            Switch(
              value: switchValue,
              onChanged: (_) {
                onToggle();
                _savePrefs();
                SnackbarUtil.showToastMessage(
                  switchValue ? '$title 알림이 꺼졌습니다.' : '$title 알림이 켜졌습니다.',
                );
              },
              activeColor: AppColor.mainYellow.of(context),
              inactiveThumbColor: AppColor.gray10.of(context),
              inactiveTrackColor: AppColor.gray20.of(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onSectionTap, // 스위치 꺼져 있어도 클릭 가능
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: sectionBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sectionText,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: enabled ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: chevronColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: ListView(
          children: [
            _buildSection(
              title: '결제일 알림',
              enabled: _paymentDayNotify,
              onToggle: () =>
                  setState(() => _paymentDayNotify = !_paymentDayNotify),
              onSectionTap: () async {
                await _showSettingDialog(
                  title: '결제일 알림 설정',
                  dayValue: _paymentDayBefore,
                  isBefore: true,
                  hourValue: _paymentDayHour,
                  minuteValue: _paymentDayMinute,
                  onDayChanged: (v) => setState(() => _paymentDayBefore = v),
                  onHourChanged: (v) => setState(() => _paymentDayHour = v),
                  onMinuteChanged: (v) => setState(() => _paymentDayMinute = v),
                );
                await _savePrefs();
              },
              sectionText:
                  '결제일 ${_paymentDayBefore}일 전부터, 매일 ${_paymentDayHour.toString().padLeft(2, '0')}시 ${_paymentDayMinute.toString().padLeft(2, '0')}분',
              sectionBg: _paymentDayNotify
                  ? AppColor.mainYellowLight3.of(context)
                  : AppColor.containerLightGray30.of(context),
              textColor: _paymentDayNotify
                  ? AppColor.mainYellow.of(context)
                  : AppColor.lightGray20.of(context),
              chevronColor: _paymentDayNotify
                  ? AppColor.mainYellow.of(context)
                  : AppColor.gray30.of(context),
              switchValue: _paymentDayNotify,
            ),
            _buildSection(
              title: '결제 확인 알림',
              enabled: _paymentConfirmNotify,
              onToggle: () => setState(
                () => _paymentConfirmNotify = !_paymentConfirmNotify,
              ),
              onSectionTap: () async {
                await _showSettingDialog(
                  title: '결제 확인 알림 설정',
                  dayValue: _paymentConfirmAfter,
                  isBefore: false,
                  hourValue: _paymentConfirmHour,
                  minuteValue: _paymentConfirmMinute,
                  onDayChanged: (v) => setState(() => _paymentConfirmAfter = v),
                  onHourChanged: (v) => setState(() => _paymentConfirmHour = v),
                  onMinuteChanged: (v) =>
                      setState(() => _paymentConfirmMinute = v),
                );
                await _savePrefs();
              },
              sectionText:
                  '결제일 이후 ${_paymentConfirmAfter}일 동안, 매일 ${_paymentConfirmHour.toString().padLeft(2, '0')}시 ${_paymentConfirmMinute.toString().padLeft(2, '0')}분',
              sectionBg: _paymentConfirmNotify
                  ? AppColor.mainYellowLight3.of(context)
                  : AppColor.containerLightGray30.of(context),
              textColor: _paymentConfirmNotify
                  ? AppColor.mainYellow.of(context)
                  : AppColor.lightGray20.of(context),
              chevronColor: _paymentConfirmNotify
                  ? AppColor.mainYellow.of(context)
                  : AppColor.gray30.of(context),
              switchValue: _paymentConfirmNotify,
            ),
          ],
        ),
      ),
    );
  }
}
