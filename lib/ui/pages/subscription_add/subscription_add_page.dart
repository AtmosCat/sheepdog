import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/viewmodel/user_info_viewmodel.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/payment_method.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/ui/ads/interstitial_ad_widget.dart';
import 'package:sheepdog/ui/pages/subscription_add/widgets/emoji_categories.dart';
import 'package:sheepdog/ui/pages/subscription_add/widgets/free_emoji_categories.dart';
import 'package:sheepdog/ui/pages/widgets/category_add_dialog.dart';
import 'package:sheepdog/ui/pages/widgets/add_payment_dialog.dart';
import 'package:sheepdog/ui/utils/fcm_utils.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';
import 'package:sheepdog/ui/utils/subscription_utlils.dart';

class _ServiceInputResult {
  final String name;
  final String emoji;
  _ServiceInputResult({required this.name, required this.emoji});
}

class _ServiceInputDialog extends StatefulWidget {
  @override
  State<_ServiceInputDialog> createState() => _ServiceInputDialogState();
}

class _ServiceInputDialogState extends State<_ServiceInputDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedEmoji;

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserInfoViewModel>(context, listen: false).userInfo;
    final isPremium = userInfo?.isPremium ?? false;
    final categoriesToShow = isPremium ? emojiCategories : freeEmojiCategories;

    return AlertDialog(
      backgroundColor: AppColor.containerWhite.of(context),
      title: Text(
        '구독 서비스 추가',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AppColor.deepBlack.of(context),
        ),
      ),
      content: SizedBox(
        width: 360,
        height: 480,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '서비스명을 입력하세요.',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  "나만의 이모지를 추가해보세요!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColor.gray20.of(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: categoriesToShow.entries.map((entry) {
                  final category = entry.key;
                  final emojis = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColor.mainBrown.of(context),
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: emojis.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                        itemBuilder: (context, index) {
                          final emoji = emojis[index];
                          final isSelected = _selectedEmoji == emoji;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedEmoji = emoji;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColor.containerGray20.of(context)
                                    : AppColor.containerLightGray10.of(context),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: TextStyle(
                                  fontSize: 28,
                                  color: isSelected
                                      ? AppColor.deepBlack.of(context)
                                      : AppColor.mainBrown.of(context),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 15),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.gray30.of(context),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            '취소',
            style: TextStyle(color: AppColor.mainYellow.of(context)),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.primaryBlue.of(context),
          ),
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              SnackbarUtil.showToastMessage('서비스명을 입력해 주세요.');
              return;
            }
            Navigator.pop(
              context,
              _ServiceInputResult(name: name, emoji: _selectedEmoji ?? "💬"),
            );
          },
          child: Text(
            '확인',
            style: TextStyle(color: AppColor.defaultBlack.of(context)),
          ),
        ),
      ],
    );
  }
}

class SubscriptionAddPage extends StatefulWidget {
  final SubscriptionService? service; // 수정 모드용
  final SubscriptionCategory? category;
  final PaymentMethod? paymentMethod;

  const SubscriptionAddPage({
    Key? key,
    this.service,
    this.category,
    this.paymentMethod,
  }) : super(key: key);

  @override
  State<SubscriptionAddPage> createState() => _SubscriptionAddPageState();
}

class _SubscriptionAddPageState extends State<SubscriptionAddPage> {
  SubscriptionService? _selectedService;
  SubscriptionCategory? _selectedCategory;
  DateTime? _selectedStartDate;
  PaymentCycle? _selectedCycle;
  dynamic _selectedDate;
  int? _selectedAmount;
  bool _isAmountUndetermined = false;
  PaymentMethod? _selectedMethod;
  String _memo = '';

  final _serviceRepo = SubscriptionServiceRepository();
  final _categoryRepo = SubscriptionCategoryRepository();
  final _methodRepo = PaymentMethodRepository();

  bool _isSaving = false;

  List<SubscriptionCategory> _allCategories = [];
  List<PaymentMethod> _allMethods = [];

  @override
  void initState() {
    super.initState();
    _loadData().then((_) {
      // 수정 모드일 때 기존 값 세팅
      if (widget.service != null) {
        final service = widget.service!;
        dynamic selectedDate;
        if (service.paymentCycle == PaymentCycle.yearly &&
            service.paymentDate != null) {
          selectedDate = service.paymentDate;
        } else if (service.paymentCycle == PaymentCycle.monthly &&
            service.paymentDate != null) {
          selectedDate = serviceIsLastDayOfMonth(service)
              ? kLastDayOfMonth
              : service.paymentDate!.day;
        } else if (service.paymentCycle == PaymentCycle.weekly &&
            service.paymentDate != null) {
          const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
          selectedDate = weekDays[service.paymentDate!.weekday - 1];
        } else {
          selectedDate = service.paymentDate;
        }

        setState(() {
          _selectedService = service;
          _selectedCategory = widget.category;
          _selectedCycle = service.paymentCycle;
          _selectedDate = selectedDate;
          _selectedAmount = serviceIsAmountUndetermined(service)
              ? null
              : service.paymentAmount;
          _isAmountUndetermined = serviceIsAmountUndetermined(service);
          _selectedMethod = widget.paymentMethod;
          _memo = service.memo;
          _selectedStartDate = service.paymentStartDate; // 결제 시작일 세팅
        });
      }
    });
  }

  Future<void> _loadData() async {
    final categories = await _categoryRepo.getAllCategories();
    final methods = await _methodRepo.getAllMethods();
    setState(() {
      _allCategories = categories;
      _allMethods = methods;
    });
  }

  void _showServiceSelectDialog() async {
    final result = await showDialog<_ServiceInputResult>(
      context: context,
      builder: (context) => _ServiceInputDialog(),
    );

    if (result != null) {
      setState(() {
        _selectedService = SubscriptionService(
          name: result.name,
          emoji: result.emoji,
          logoUrl: null,
          categoryId: '',
          paymentCycle: null,
          paymentDate: null,
          paymentAmount: null,
          paymentMethodId: '',
          memo: '',
          paymentStartDate: DateTime.now(), // 결제 시작일 필수 파라미터 추가
        );
      });
    }
  }

  void _showCategorySelectDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return CategorySelectDialog(
          categories: _allCategories,
          onSelect: (category) {
            setState(() => _selectedCategory = category);
          },
          onAdd: () async {
            final newCategory = await showDialog<SubscriptionCategory>(
              context: context,
              builder: (context) => CategoryAddDialog(),
            );
            if (newCategory != null) {
              await _categoryRepo.addCategory(newCategory);
              await _loadData();
              setState(() => _selectedCategory = newCategory);
              Navigator.of(context, rootNavigator: true).pop(); // 모든 다이얼로그 닫기
              SnackbarUtil.showToastMessage("카테고리가 추가되었습니다.");
            }
          },
        );
      },
    );
  }

  void _showCycleSelectDialog() async {
    final result = await showDialog<PaymentCycle>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: AppColor.containerWhite.of(context),
          title: Text(
            '결제 주기 선택',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColor.deepBlack.of(context),
            ),
          ),
          children: PaymentCycle.values.map((cycle) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, cycle),
              child: Text(
                cycleToText(cycle),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColor.deepBlack.of(context),
                  fontWeight: FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedCycle = result;
        _selectedDate = null; // 결제 주기 선택 시 결제일 초기화
      });
    }
  }

  void _showDateSelectDialog() async {
    if (_selectedCycle == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 결제 주기를 선택해 주세요.')));
      return;
    }
    if (_selectedCycle == PaymentCycle.yearly) {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.mainYellow.of(context),
              onPrimary: Colors.black,
              surface: AppColor.containerWhite.of(context),
              onSurface: AppColor.deepBlack.of(context),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) setState(() => _selectedDate = picked);
    } else if (_selectedCycle == PaymentCycle.monthly) {
      final result = await showDialog<int>(
        context: context,
        builder: (context) {
          // 1~31일 + 말일(짧거나 긴 달에 대응)
          final options = <MapEntry<int, String>>[
            for (int day = 1; day <= 31; day++) MapEntry(day, '$day일'),
            const MapEntry(kLastDayOfMonth, '말일'),
          ];
          return SimpleDialog(
            backgroundColor: AppColor.containerWhite.of(context),
            title: Text(
              '결제일 선택',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColor.deepBlack.of(context),
              ),
            ),
            children: options.map((entry) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, entry.key),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColor.deepBlack.of(context),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
      if (result != null) setState(() => _selectedDate = result);
    } else if (_selectedCycle == PaymentCycle.weekly) {
      final days = ['월', '화', '수', '목', '금', '토', '일'];
      final result = await showDialog<String>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            backgroundColor: AppColor.containerWhite.of(context),
            title: Text(
              '결제 요일 선택',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColor.deepBlack.of(context),
              ),
            ),
            children: days.map((d) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, d),
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColor.deepBlack.of(context),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
      if (result != null) setState(() => _selectedDate = result);
    }
  }

  void _showAmountInputDialog() async {
    final result = await showDialog<_AmountInputResult>(
      context: context,
      builder: (context) {
        return _AmountInputDialog(
          initialAmount: _selectedAmount,
          initialUndetermined: _isAmountUndetermined,
        );
      },
    );
    if (result == null) return;
    setState(() {
      _isAmountUndetermined = result.isUndetermined;
      _selectedAmount = result.isUndetermined ? null : result.amount;
    });
  }

  void _showMethodSelectDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return PaymentMethodSelectDialog(
          methods: _allMethods,
          onSelect: (method) {
            setState(() => _selectedMethod = method);
          },
          onAdd: () async {
            final newMethod = await showDialog<PaymentMethod>(
              context: context,
              builder: (context) => AddPaymentMethodDialog(),
            );
            if (newMethod != null) {
              // DB에 이미 저장된 상태이므로, 리스트에 추가 후 선택만 하면 됨
              setState(() {
                _allMethods.add(newMethod);
                _selectedMethod = newMethod;
              });
              // 다이얼로그를 모두 닫고 SubscriptionAddPage로 복귀
              Navigator.of(
                context,
                rootNavigator: true,
              ).pop(); // PaymentMethodSelectDialog 닫기
            }
          },
        );
      },
    );
  }

  void _saveSubscription() async {
    List<String> missingFields = [];

    if (_selectedService == null) {
      missingFields.add('구독 서비스');
    }
    if (_selectedCycle == null) {
      missingFields.add('결제 주기');
    }
    if (_selectedDate == null) {
      missingFields.add('결제일');
    }
    if (!_isAmountUndetermined && _selectedAmount == null) {
      missingFields.add('결제 금액');
    }
    if (_selectedStartDate == null) {
      missingFields.add('시작일');
    }

    if (missingFields.isNotEmpty) {
      SnackbarUtil.showToastMessage(
        '다음 항목을 입력해 주세요: ${missingFields.join(', ')}',
      );
      return;
    }

    setState(() => _isSaving = true);

    final isEdit = widget.service != null;

    final isLastDayOfMonth =
        _selectedCycle == PaymentCycle.monthly &&
        _selectedDate is int &&
        _selectedDate == kLastDayOfMonth;

    final service = SubscriptionService(
      id: isEdit ? widget.service!.id : null,
      name: _selectedService!.name,
      logoUrl: '',
      emoji: _selectedService!.emoji,
      categoryId: _selectedCategory?.id,
      paymentCycle: _selectedCycle,
      paymentDate: _getPaymentDate(),
      paymentAmount: _isAmountUndetermined ? null : _selectedAmount,
      paymentMethodId: _selectedMethod?.id,
      memo: _memo,
      createdAt: isEdit ? widget.service!.createdAt : DateTime.now(),
      paymentStartDate: _selectedStartDate!,
      isLastDayOfMonth: isLastDayOfMonth,
      isAmountUndetermined: _isAmountUndetermined,
    );

    try {
      if (isEdit) {
        await _serviceRepo.updateService(service);
      } else {
        await _serviceRepo.addService(service);
      }

      // 알림 설정 동기화는 실패해도 저장/이동을 막지 않음
      try {
        final updatedSubscriptions = await _serviceRepo.getAllServices();
        await FCMUtils().saveUserNotificationSettings(
          subscriptions: updatedSubscriptions,
        );
      } catch (_) {}

      if (!mounted) return;

      final isPremium =
          Provider.of<UserInfoViewModel>(
            context,
            listen: false,
          ).userInfo?.isPremium ??
          false;

      final successMessage =
          isEdit ? '구독이 수정되었습니다.' : '구독이 추가되었습니다.';

      await InterstitialAdWidget(isPremium: isPremium).showInterstitialAdIfAvailable(
        onClosed: () {
          if (!mounted) return;
          SnackbarUtil.showToastMessage(successMessage);
          Navigator.pop(context, true);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackbarUtil.showToastMessage('저장에 실패했습니다. 다시 시도해 주세요.');
    }
  }

  DateTime? _getPaymentDate() {
    if (_selectedCycle == PaymentCycle.yearly && _selectedDate is DateTime) {
      return _selectedDate as DateTime;
    }
    if (_selectedCycle == PaymentCycle.monthly && _selectedDate is int) {
      final now = DateTime.now();
      final day = _selectedDate as int;
      // 말일이면 이번 달 말일을 기준값으로 저장 (계산은 isLastDayOfMonth로 처리)
      if (day == kLastDayOfMonth) {
        return resolveMonthlyPaymentDate(
          now.year,
          now.month,
          preferredDay: 1,
          isLastDayOfMonth: true,
        );
      }
      return resolveMonthlyPaymentDate(
        now.year,
        now.month,
        preferredDay: day,
      );
    }
    if (_selectedCycle == PaymentCycle.weekly && _selectedDate is String) {
      // 요일 문자열을 DateTime의 weekday(1~7)로 변환
      const dayMap = {'월': 1, '화': 2, '수': 3, '목': 4, '금': 5, '토': 6, '일': 7};
      final now = DateTime.now();
      final selectedWeekday = dayMap[_selectedDate];
      if (selectedWeekday == null) return null;
      // 오늘이 선택 요일이면 오늘, 아니면 다음 해당 요일
      int diff = (selectedWeekday - now.weekday) % 7;
      if (diff < 0) diff += 7;
      return now.add(Duration(days: diff));
    }
    return null;
  }

  String _formatAmount(int? amount) {
    if (amount == null) return '';
    return NumberFormat('#,###원', 'ko_KR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSaving) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColor.mainYellow.of(context)),
              SizedBox(height: 16),
              Text('저장 중입니다. 잠시만 기다려 주세요.'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColor.containerWhite.of(context),
      appBar: AppBar(
        title: Text(widget.service != null ? '구독 수정' : '구독 추가'),
        centerTitle: true,
        backgroundColor: AppColor.containerWhite.of(context),
        foregroundColor: AppColor.deepBlack.of(context),
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          // 구독 서비스
          _Section(
            iconAsset: 'lib/assets/icons/subscribe.png',
            label: '구독 서비스',
            child: _SelectableRow(
              onTap: _showServiceSelectDialog,
              valueWidget: _selectedService != null
                  ? Row(
                      children: [
                        // 이모지 표시 (logoUrl이 null일 때)
                        if (_selectedService!.emoji != null)
                          CircleAvatar(
                            backgroundColor: AppColor.containerWhite.of(
                              context,
                            ),
                            radius: 16,
                            child: Padding(
                              padding: const EdgeInsets.all(0.0), // 내부 여백 조정
                              child: Text(
                                _selectedService!.emoji!,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          )
                        // 아무것도 없을 때 기본 아이콘
                        else
                          CircleAvatar(
                            backgroundColor: AppColor.containerWhite.of(
                              context,
                            ),
                            radius: 16,
                            child: Icon(
                              Icons.apps,
                              color: AppColor.mainBrown.of(context),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedService!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      '필수',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // 카테고리
          _Section(
            icon: Icons.category,
            label: '카테고리',
            child: _SelectableRow(
              onTap: _showCategorySelectDialog,
              valueWidget:
                  (_selectedCategory != null &&
                      _selectedCategory!.name.isNotEmpty)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(
                          _selectedCategory!.colorValue ?? 0xFFCCCCCC,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedCategory!.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    )
                  : const Text(
                      '선택',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),
          // 결제 시작일
          _Section(
            iconAsset: 'lib/assets/icons/flag.png',
            label: '시작일',
            child: _SelectableRow(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedStartDate ?? now,
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 5),
                  locale: const Locale('ko', 'KR'),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColor.mainYellow.of(context),
                          onPrimary: Colors.black,
                          surface: AppColor.containerWhite.of(context),
                          onSurface: AppColor.deepBlack.of(context),
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColor.mainYellow.of(context),
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _selectedStartDate = picked;
                  });
                }
              },
              valueWidget: _selectedStartDate != null
                  ? Text(
                      '${_selectedStartDate!.year}년 ${_selectedStartDate!.month.toString().padLeft(2, '0')}월 ${_selectedStartDate!.day.toString().padLeft(2, '0')}일',
                      style: TextStyle(
                        color: AppColor.deepBlack.of(context),
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                    )
                  : const Text(
                      '필수',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),
          // 결제 주기
          _Section(
            icon: Icons.repeat,
            label: '결제 주기',
            child: _SelectableRow(
              onTap: _showCycleSelectDialog,
              valueWidget: Text(
                cycleToText(_selectedCycle) == ''
                    ? '필수'
                    : cycleToText(_selectedCycle),
                style: TextStyle(
                  color: _selectedCycle == null
                      ? Colors.grey
                      : AppColor.deepBlack.of(context),
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 결제일
          _Section(
            icon: Icons.calendar_today,
            label: '결제일',
            child: _SelectableRow(
              onTap: _showDateSelectDialog,
              valueWidget: Text(
                _selectedDate == null
                    ? '필수'
                    : (_selectedCycle == PaymentCycle.yearly
                          ? (_selectedDate as DateTime).toString().split(' ')[0]
                          : (_selectedCycle == PaymentCycle.monthly &&
                                    _selectedDate is int
                                ? ((_selectedDate as int) == kLastDayOfMonth
                                      ? '말일'
                                      : '${_selectedDate}일')
                                : _selectedDate.toString())),
                style: TextStyle(
                  color: _selectedDate == null
                      ? Colors.grey
                      : AppColor.deepBlack.of(context),
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 결제 금액
          _Section(
            iconAsset: 'lib/assets/icons/coin.png',
            label: '결제 금액',
            child: _SelectableRow(
              onTap: _showAmountInputDialog,
              valueWidget: Text(
                _isAmountUndetermined
                    ? kUndeterminedAmountLabel
                    : (_selectedAmount == null
                          ? '필수'
                          : _formatAmount(_selectedAmount)),
                style: TextStyle(
                  color: _isAmountUndetermined || _selectedAmount != null
                      ? AppColor.deepBlack.of(context)
                      : Colors.grey,
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 결제 수단
          _Section(
            icon: Icons.credit_card,
            label: '결제 수단',
            child: _SelectableRow(
              onTap: _showMethodSelectDialog,
              valueWidget: _selectedMethod != null
                  ? Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColor.containerWhite.of(context),
                          radius: 18,
                          child: Icon(
                            Icons.credit_card,
                            color: AppColor.mainYellow.of(context),
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 12), // 기존 8 -> 12로 증가
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedMethod!.serviceName ?? '',
                              style: const TextStyle(
                                fontSize: 13, // 기존 10 -> 13으로 증가
                                color: Colors.grey,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Text(
                              _selectedMethod!.alias,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16, // 기존 13 -> 16으로 증가
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const Text(
                      '선택',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // 메모
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: AppColor.deepBlack.of(context),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "메모",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColor.deepBlack.of(context),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: '선택',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 14,
                        ),
                      ),
                      onChanged: (v) => _memo = v,
                      onTapOutside: (event) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // 저장 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.mainYellow.of(context),
                foregroundColor: AppColor.deepBlack.of(context),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSaving ? null : _saveSubscription,
              icon: const Icon(Icons.save),
              label: Text(
                widget.service != null ? '수정하기' : '저장하기',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(height: 140),
        ],
      ),
    );
  }
}

// 각 항목 섹션
class _Section extends StatelessWidget {
  final IconData? icon;
  final String? iconAsset;
  final String label;
  final Widget child;

  const _Section({
    this.icon,
    this.iconAsset,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final Widget leading = iconAsset != null
        ? Image.asset(
            iconAsset!,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          )
        : Icon(icon ?? Icons.circle, color: AppColor.deepBlack.of(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColor.deepBlack.of(context),
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// 선택 가능한 섹션
class _SelectableRow extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget valueWidget;

  const _SelectableRow({required this.onTap, required this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColor.containerLightGray30.of(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            valueWidget,
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColor.gray20.of(context)),
          ],
        ),
      ),
    );
  }
}

// 카테고리 선택 다이얼로그
class CategorySelectDialog extends StatelessWidget {
  final List<SubscriptionCategory> categories;
  final void Function(SubscriptionCategory) onSelect;
  final VoidCallback onAdd;

  const CategorySelectDialog({
    required this.categories,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.containerWhite.of(context),
      title: Row(
        children: [
          Text(
            '카테고리 선택',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColor.deepBlack.of(context),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            color: AppColor.deepBlack.of(context),
            onPressed: onAdd,
          ),
        ],
      ),
      content: categories.isEmpty
          ? const Text('추가된 카테고리가 없습니다')
          : SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 12,
                children: categories
                    .map(
                      (cat) => GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(cat);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(cat.colorValue ?? 0xFFCCCCCC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}

// 결제수단 선택 다이얼로그
class PaymentMethodSelectDialog extends StatelessWidget {
  final List<PaymentMethod> methods;
  final void Function(PaymentMethod) onSelect;
  final VoidCallback onAdd;

  const PaymentMethodSelectDialog({
    required this.methods,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.containerWhite.of(context),
      title: Row(
        children: [
          Text(
            '결제 수단 선택',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColor.deepBlack.of(context),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            color: AppColor.deepBlack.of(context),
            onPressed: onAdd,
          ),
        ],
      ),
      content: methods.isEmpty
          ? const Text('추가된 결제 수단이 없습니다')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: methods
                  .map(
                    (method) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColor.containerWhite.of(context),
                        radius: 18,
                        child: Icon(
                          Icons.credit_card,
                          color: AppColor.mainYellow.of(context),
                        ),
                      ),
                      title: Text(
                        method.serviceName ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        method.alias,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(method);
                      },
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _AmountInputResult {
  final int? amount;
  final bool isUndetermined;

  const _AmountInputResult({
    this.amount,
    this.isUndetermined = false,
  });
}

class _AmountInputDialog extends StatefulWidget {
  const _AmountInputDialog({
    required this.initialAmount,
    required this.initialUndetermined,
  });

  final int? initialAmount;
  final bool initialUndetermined;

  @override
  State<_AmountInputDialog> createState() => _AmountInputDialogState();
}

class _AmountInputDialogState extends State<_AmountInputDialog> {
  late final TextEditingController _controller;
  late bool _isUndetermined;

  @override
  void initState() {
    super.initState();
    _isUndetermined = widget.initialUndetermined;
    _controller = TextEditingController(
      text: widget.initialUndetermined ? '' : (widget.initialAmount?.toString() ?? ''),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isUndetermined) {
      Navigator.pop(
        context,
        const _AmountInputResult(isUndetermined: true),
      );
      return;
    }

    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      SnackbarUtil.showToastMessage('금액을 입력해 주세요.');
      return;
    }

    Navigator.pop(context, _AmountInputResult(amount: value));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.containerWhite.of(context),
      title: Text(
        '결제 금액 입력',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AppColor.deepBlack.of(context),
        ),
      ),
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              enabled: !_isUndetermined,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '금액을 입력하세요.',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                border: const OutlineInputBorder(),
                filled: _isUndetermined,
                fillColor: _isUndetermined ? Colors.grey.shade100 : null,
              ),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _isUndetermined,
              onChanged: (checked) {
                setState(() {
                  _isUndetermined = checked ?? false;
                  if (_isUndetermined) {
                    _controller.clear();
                  }
                });
              },
              title: Text(
                kUndeterminedAmountLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.deepBlack.of(context),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.gray30.of(context),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            '취소',
            style: TextStyle(color: AppColor.mainYellow.of(context)),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.primaryBlue.of(context),
          ),
          onPressed: _submit,
          child: Text(
            '확인',
            style: TextStyle(color: AppColor.defaultBlack.of(context)),
          ),
        ),
      ],
    );
  }
}
