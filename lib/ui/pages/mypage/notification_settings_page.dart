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
  // 결제 전 알림
  bool _beforeNotify = true;
  int _beforeHour = 9;
  int _beforeMinute = 0;

  // 결제 당일 알림
  bool _onNotify = true;
  int _onHour = 9;
  int _onMinute = 0;

  // 결제 후 알림
  bool _afterNotify = false;
  int _afterDays = 2;
  int _afterHour = 18;
  int _afterMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _beforeNotify = prefs.getBool('beforeNotify') ?? true;
      _beforeHour = prefs.getInt('beforeHour') ?? 9;
      _beforeMinute = prefs.getInt('beforeMinute') ?? 0;

      _onNotify = prefs.getBool('onNotify') ?? true;
      _onHour = prefs.getInt('onHour') ?? 9;
      _onMinute = prefs.getInt('onMinute') ?? 0;

      _afterNotify = prefs.getBool('afterNotify') ?? false;
      _afterDays = prefs.getInt('afterDays') ?? 2;
      _afterHour = prefs.getInt('afterHour') ?? 18;
      _afterMinute = prefs.getInt('afterMinute') ?? 0;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('beforeNotify', _beforeNotify);
    await prefs.setInt('beforeHour', _beforeHour);
    await prefs.setInt('beforeMinute', _beforeMinute);

    await prefs.setBool('onNotify', _onNotify);
    await prefs.setInt('onHour', _onHour);
    await prefs.setInt('onMinute', _onMinute);

    await prefs.setBool('afterNotify', _afterNotify);
    await prefs.setInt('afterDays', _afterDays);
    await prefs.setInt('afterHour', _afterHour);
    await prefs.setInt('afterMinute', _afterMinute);
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h시 $m분';
  }

  Future<void> _showBeforeDialog() async {
    int tempHour = _beforeHour;
    int tempMinute = _beforeMinute;

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
                    '결제 전 알림 설정',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '결제일 하루 전에 알림이 전송돼요.',
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
                  SizedBox(height: 16),
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
                            _beforeHour = tempHour;
                            _beforeMinute = tempMinute;
                          });
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

  Future<void> _showOnDialog() async {
    int tempHour = _onHour;
    int tempMinute = _onMinute;

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
                    '결제 당일 알림 설정',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '결제가 발생하는 날 알림을 보내드려요.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '알림 전송 시각',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 16),
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
                            _onHour = tempHour;
                            _onMinute = tempMinute;
                          });
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

  Future<void> _showAfterDialog() async {
    int tempDay = _afterDays;
    int tempHour = _afterHour;
    int tempMinute = _afterMinute;

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
                    '결제 후 알림 설정',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '결제가 발생한 다음날, 확인 알림을 보내드려요.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '알림 전송 시각',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 16),
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
                            _afterDays = tempDay;
                            _afterHour = tempHour;
                            _afterMinute = tempMinute;
                          });
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
          onTap: onSectionTap,
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
              title: '결제 전 알림',
              enabled: _beforeNotify,
              onToggle: () => setState(() => _beforeNotify = !_beforeNotify),
              onSectionTap: _showBeforeDialog,
              sectionText:
                  '결제일 하루 전, ${_formatTime(_beforeHour, _beforeMinute)}',
              sectionBg: _beforeNotify
                  ? AppColor.mainYellowLight3.of(context)
                  : AppColor.containerLightGray30.of(context),
              textColor: _beforeNotify
                  ? AppColor.mainYellow.of(context)
                  : AppColor.lightGray20.of(context),
              chevronColor: _beforeNotify
                  ? AppColor.mainYellow.of(context)
                  : AppColor.gray30.of(context),
              switchValue: _beforeNotify,
            ),
            _buildSection(
              title: '결제 당일 알림',
              enabled: _onNotify,
              onToggle: () => setState(() => _onNotify = !_onNotify),
              onSectionTap: _showOnDialog,
              sectionText: '결제 당일, ${_formatTime(_onHour, _onMinute)}',
              sectionBg: _onNotify
                  ? AppColor.mainYellowLight3.of(context)
                  : AppColor.containerLightGray30.of(context),
              textColor: _onNotify
                  ? AppColor.mainYellow.of(context)
                  : AppColor.lightGray20.of(context),
              chevronColor: _onNotify
                  ? AppColor.mainYellow.of(context)
                  : AppColor.gray30.of(context),
              switchValue: _onNotify,
            ),
            _buildSection(
              title: '결제 후 알림',
              enabled: _afterNotify,
              onToggle: () => setState(() => _afterNotify = !_afterNotify),
              onSectionTap: _showAfterDialog,
              sectionText:
                  '결제 후 ${_afterDays}일, ${_formatTime(_afterHour, _afterMinute)}',
              sectionBg: _afterNotify
                  ? AppColor.mainYellowLight3.of(context)
                  : AppColor.containerLightGray30.of(context),
              textColor: _afterNotify
                  ? AppColor.mainYellow.of(context)
                  : AppColor.lightGray20.of(context),
              chevronColor: _afterNotify
                  ? AppColor.mainYellow.of(context)
                  : AppColor.gray30.of(context),
              switchValue: _afterNotify,
            ),
          ],
        ),
      ),
    );
  }
}
