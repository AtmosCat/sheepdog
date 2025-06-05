import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // 컬러 팔레트용
import 'package:intl/intl.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/payment_method.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/ui/pages/subscription_add/widgets/emoji_categories.dart';
import 'package:sheepdog/ui/pages/subscription_add/widgets/light_pastel_colors.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';

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
                children: emojiCategories.entries.map((entry) {
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
          child: const Text('취소'),
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
          child: const Text('확인'),
        ),
      ],
    );
  }
}

class AddPaymentMethodDialog extends StatefulWidget {
  @override
  State<AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<AddPaymentMethodDialog> {
  String _selectedCategory = '은행';
  String? _selectedId;
  String _alias = '';
  String _memo = '';

  static const Map<String, List<Map<String, String>>> _methodData = {
    '은행': [
      {'name': '국민은행', 'asset': 'lib/assets/images/bank/kookminbank.png'},
      {'name': '신한은행', 'asset': 'lib/assets/images/bank/shinhanbank.png'},
      {'name': 'NH농협은행', 'asset': 'lib/assets/images/bank/nhbank.png'},
      {'name': '지역농협', 'asset': 'lib/assets/images/bank/nhbank2.png'},
      {'name': '하나은행', 'asset': 'lib/assets/images/bank/hanabank.png'},
      {'name': '우리은행', 'asset': 'lib/assets/images/bank/wooribank.png'},
      {'name': 'IBK기업은행', 'asset': 'lib/assets/images/bank/ibkbank.png'},
      {'name': '케이뱅크', 'asset': 'lib/assets/images/bank/kbank.png'},
      {'name': '카카오뱅크', 'asset': 'lib/assets/images/bank/kakaobank.png'},
      {'name': '토스뱅크', 'asset': 'lib/assets/images/bank/tossbank.png'},
      {'name': 'MG새마을금고', 'asset': 'lib/assets/images/bank/mgbank.png'},
      {'name': '우체국', 'asset': 'lib/assets/images/bank/postofficebank.png'},
      {'name': 'SC제일은행', 'asset': 'lib/assets/images/bank/scbank.png'},
      {'name': '신협', 'asset': 'lib/assets/images/bank/shinhyupbank.png'},
      {'name': '수협은행', 'asset': 'lib/assets/images/bank/suhyupbank.png'},
      {
        'name': '수협중앙회',
        'asset': 'lib/assets/images/bank/suhyupcentralbank.png',
      },
      {'name': '부산은행', 'asset': 'lib/assets/images/bank/busanbank.png'},
      {'name': '경남은행', 'asset': 'lib/assets/images/bank/gyungnambank.png'},
      {'name': '광주은행', 'asset': 'lib/assets/images/bank/gwangjubank.png'},
      {'name': '전북은행', 'asset': 'lib/assets/images/bank/jeonbukbank.png'},
      {'name': '제주은행', 'asset': 'lib/assets/images/bank/jejubank.png'},
      {'name': 'KDB산업은행', 'asset': 'lib/assets/images/bank/kdbbank.png'},
      {'name': '씨티은행', 'asset': 'lib/assets/images/bank/citibank.png'},
      {'name': '한국수출입은행', 'asset': 'lib/assets/images/bank/tradebank.png'},
      {'name': 'SBI저축은행', 'asset': 'lib/assets/images/bank/sbibank.png'},
      {'name': 'IM뱅크', 'asset': 'lib/assets/images/bank/imbank.png'},
    ],
    '카드': [
      {'name': '국민카드', 'asset': 'lib/assets/images/card/kookminbankcard.png'},
      {'name': '신한카드', 'asset': 'lib/assets/images/card/shinhanbankcard.png'},
      {'name': 'NH농협카드', 'asset': 'lib/assets/images/card/nhbankcard.png'},
      {'name': '하나카드', 'asset': 'lib/assets/images/card/hanabankcard.png'},
      {'name': '우리카드', 'asset': 'lib/assets/images/card/wooribankcard.png'},
      {'name': '삼성카드', 'asset': 'lib/assets/images/card/samsungcard.png'},
      {'name': '카카오뱅크카드', 'asset': 'lib/assets/images/card/kakaobankcard.png'},
      {'name': '케이뱅크카드', 'asset': 'lib/assets/images/card/kbankcard.png'},
      {'name': '토스뱅크카드', 'asset': 'lib/assets/images/card/tossbankcard.png'},
      {'name': 'BC카드', 'asset': 'lib/assets/images/card/bccard.png'},
      {'name': '롯데카드', 'asset': 'lib/assets/images/card/lottecard.png'},
      {'name': '현대카드', 'asset': 'lib/assets/images/card/hyandaicard.png'},
      {'name': 'MG새마을금고카드', 'asset': 'lib/assets/images/card/mgbankcard.png'},
      {'name': 'IBK기업은행카드', 'asset': 'lib/assets/images/card/ibkbankcard.png'},
      {'name': '씨티은행카드', 'asset': 'lib/assets/images/card/citibankcard.png'},
      {'name': '전북은행카드', 'asset': 'lib/assets/images/card/jeonbukbankcard.png'},
      {'name': '광주은행카드', 'asset': 'lib/assets/images/card/gwangjubankcard.png'},
      {'name': 'KDB산업은행카드', 'asset': 'lib/assets/images/card/kdbbankcard.png'},
      {'name': '제주은행카드', 'asset': 'lib/assets/images/card/jejubankcard.png'},
      {'name': '수협카드', 'asset': 'lib/assets/images/card/suhyupbankcard.png'},
      {
        'name': '경남은행카드',
        'asset': 'lib/assets/images/card/gyungnambankcard.png',
      },
      {'name': '부산은행카드', 'asset': 'lib/assets/images/card/busanbankcard.png'},
      {'name': 'IM뱅크카드', 'asset': 'lib/assets/images/card/imbankcard.png'},
      {'name': 'SC제일은행카드', 'asset': 'lib/assets/images/card/scbankcard.png'},
      {'name': '신협카드', 'asset': 'lib/assets/images/card/shinhyupbankcard.png'},
      {
        'name': '우체국카드',
        'asset': 'lib/assets/images/card/postofficebankcard.png',
      },
    ],
    '간편결제': [
      {'name': '카카오페이', 'asset': 'lib/assets/images/pay/kakaopay.png'},
      {'name': '네이버페이', 'asset': 'lib/assets/images/pay/naverpay.png'},
      {'name': '토스페이', 'asset': 'lib/assets/images/pay/tosspay.png'},
      {'name': '페이코', 'asset': 'lib/assets/images/pay/payco.png'},
      {'name': '스마일페이', 'asset': 'lib/assets/images/pay/smilepay.png'},
      {'name': '쿠페이', 'asset': 'lib/assets/images/pay/coupay.png'},
      {'name': 'SSG페이', 'asset': 'lib/assets/images/pay/ssgpay.png'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final methods = _methodData[_selectedCategory]!;
    return AlertDialog(
      backgroundColor: AppColor.containerWhite.of(context),
      title: Text(
        '결제 수단 추가',
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
          children: [
            // 상단 분류 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['은행', '카드', '간편결제'].map((cat) {
                final selected = _selectedCategory == cat;
                return ChoiceChip(
                  backgroundColor: AppColor.containerWhite.of(context),
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat;
                      _selectedId = null;
                    });
                  },
                  selectedColor: AppColor.mainYellow.of(context),
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColor.deepBlack.of(context)
                        : AppColor.mainBrown.of(context),
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 금융기관 리스트
            Expanded(
              child: ListView.builder(
                itemCount: methods.length,
                itemBuilder: (context, idx) {
                  final item = methods[idx];
                  final isSelected = _selectedId == item['name'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColor.containerWhite.of(context),
                      radius: 18,
                      child: Padding(
                        padding: EdgeInsets.all(4.0), // 원 안쪽 여백
                        child: ClipOval(
                          child: Image.asset(
                            item['asset']!,
                            fit: BoxFit.contain,
                            width: 32, // 이미지 크기 조절
                            height: 32,
                          ),
                        ),
                      ),
                    ),

                    title: Text(
                      item['name']!,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColor.mainBrown.of(context)
                            : AppColor.deepBlack.of(context),
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedId = item['name']);
                    },
                    selected: isSelected,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 별칭, 메모 입력란
            TextField(
              decoration: const InputDecoration(
                hintText: '별칭을 입력하세요.',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _alias = v,
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
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
          child: const Text('취소'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.primaryBlue.of(context),
          ),
          onPressed: () async {
            if (_selectedId == null || _alias.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('금융기관과 별칭을 모두 입력해 주세요.')),
              );
              return;
            }
            final selected = methods.firstWhere(
              (el) => el['name'] == _selectedId,
            );
            final newMethod = PaymentMethod(
              serviceName: selected['name'],
              logoUrl: selected['asset'],
              alias: _alias.trim(),
              memo: '', // 메모는 더 이상 사용하지 않음
              createdAt: DateTime.now(), // 등록일시 저장
            );
            await PaymentMethodRepository().addMethod(newMethod); // 반드시 await!
            Navigator.pop(context, newMethod); // 다이얼로그 닫고 PaymentMethod 반환
            SnackbarUtil.showToastMessage("결제 수단이 추가되었습니다.");
          },

          child: const Text('저장'),
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
  PaymentCycle? _selectedCycle;
  dynamic _selectedDate;
  int? _selectedAmount;
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
          // 매년: DateTime 그대로 사용
          selectedDate = service.paymentDate;
        } else if (service.paymentCycle == PaymentCycle.monthly &&
            service.paymentDate != null) {
          // 매월: 일(day)만 추출
          selectedDate = service.paymentDate!.day;
        } else if (service.paymentCycle == PaymentCycle.weekly &&
            service.paymentDate != null) {
          // 매주: 요일 문자열로 변환
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
          _selectedAmount = service.paymentAmount;
          _selectedMethod = widget.paymentMethod;
          _memo = service.memo;
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
                _cycleToText(cycle),
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
            dialogBackgroundColor: AppColor.containerWhite.of(context),
            colorScheme: ColorScheme.light(
              primary: AppColor.primaryBlue.of(context),
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
            children: List.generate(28, (i) {
              final day = i + 1;
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, day),
                child: Text(
                  '$day일',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColor.deepBlack.of(context),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              );
            }),
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
    final controller = TextEditingController(
      text: _selectedAmount?.toString() ?? '',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
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
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '금액을 입력하세요.',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                border: OutlineInputBorder(),
              ),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColor.gray30.of(context),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColor.primaryBlue.of(context),
              ),
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.pop(context, value);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    if (result != null) setState(() => _selectedAmount = result);
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
    if (_selectedService == null ||
        _selectedCategory == null ||
        _selectedCycle == null ||
        _selectedDate == null ||
        _selectedAmount == null ||
        _selectedMethod == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해 주세요.')));
      return;
    }
    setState(() => _isSaving = true);

    // 수정 모드 여부 확인 (widget.service 존재 시)
    final isEdit = widget.service != null;

    final service = SubscriptionService(
      id: isEdit ? widget.service!.id : null, // 수정이면 기존 id 사용
      name: _selectedService!.name,
      logoUrl: '',
      emoji: _selectedService!.emoji,
      categoryId: _selectedCategory!.id,
      paymentCycle: _selectedCycle,
      paymentDate: _getPaymentDate(),
      paymentAmount: _selectedAmount,
      paymentMethodId: _selectedMethod!.id,
      memo: _memo,
      createdAt: isEdit
          ? widget.service!.createdAt
          : DateTime.now(), // 수정이면 기존 등록일시 유지
    );

    if (isEdit) {
      await _serviceRepo.updateService(service); // 수정
    } else {
      await _serviceRepo.addService(service); // 신규 추가
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? '구독이 수정되었습니다.' : '구독이 추가되었습니다.')),
      );
      Navigator.pop(context, true);
    }
  }

  DateTime? _getPaymentDate() {
    if (_selectedCycle == PaymentCycle.yearly && _selectedDate is DateTime) {
      return _selectedDate as DateTime;
    }
    if (_selectedCycle == PaymentCycle.monthly && _selectedDate is int) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, _selectedDate as int);
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

  String _cycleToText(PaymentCycle? cycle) {
    switch (cycle) {
      case PaymentCycle.yearly:
        return '매년';
      case PaymentCycle.monthly:
        return '매월';
      case PaymentCycle.weekly:
        return '매주';
      default:
        return '';
    }
  }

  String _formatAmount(int? amount) {
    if (amount == null) return '';
    return NumberFormat('#,###원', 'ko_KR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icons.apps,
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
          // 카테고리
          _Section(
            icon: Icons.category,
            label: '카테고리',
            child: _SelectableRow(
              onTap: _showCategorySelectDialog,
              valueWidget: _selectedCategory != null
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
          // 결제 주기
          _Section(
            icon: Icons.repeat,
            label: '결제 주기',
            child: _SelectableRow(
              onTap: _showCycleSelectDialog,
              valueWidget: Text(
                _cycleToText(_selectedCycle) == ''
                    ? '선택'
                    : _cycleToText(_selectedCycle),
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
                    ? '선택'
                    : (_selectedCycle == PaymentCycle.yearly
                          ? (_selectedDate as DateTime).toString().split(' ')[0]
                          : _selectedDate.toString() +
                                (_selectedCycle == PaymentCycle.monthly
                                    ? '일'
                                    : '')),
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
            icon: Icons.attach_money,
            label: '결제 금액',
            child: _SelectableRow(
              onTap: _showAmountInputDialog,
              valueWidget: Text(
                _selectedAmount == null ? '선택' : _formatAmount(_selectedAmount),
                style: TextStyle(
                  color: _selectedAmount == null
                      ? Colors.grey
                      : AppColor.deepBlack.of(context),
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
                          child: _selectedMethod!.logoUrl != null
                              ? Padding(
                                  padding: const EdgeInsets.all(
                                    3.0,
                                  ), // 원과 이미지 사이 여백
                                  child: ClipOval(
                                    child: Image.asset(
                                      _selectedMethod!.logoUrl!,
                                      width: 28, // (radius보다 작게)
                                      height: 28,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.credit_card,
                                  color: AppColor.mainBrown.of(context),
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
                        hintText: '메모를 입력하세요',
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
  final IconData icon;
  final String label;
  final Widget child;

  const _Section({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColor.deepBlack.of(context)),
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
                spacing: 8, // 가로 간격
                runSpacing: 12, // 줄(행) 간 세로 간격
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

// 카테고리 추가 다이얼로그 (컬러팔레트 포함)
class CategoryAddDialog extends StatefulWidget {
  @override
  State<CategoryAddDialog> createState() => _CategoryAddDialogState();
}

class _CategoryAddDialogState extends State<CategoryAddDialog> {
  final _nameController = TextEditingController();
  int? _colorValue;
  Color _pickerColor = const Color.fromARGB(255, 162, 226, 255);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.containerWhite.of(context),
      title: Row(
        children: [
          Text(
            '카테고리 추가',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColor.deepBlack.of(context),
            ),
          ),
          Spacer(),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: AppColor.containerWhite.of(context),
                        title: Text(
                          '컬러 선택',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColor.deepBlack.of(context),
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: BlockPicker(
                            pickerColor: _pickerColor,
                            onColorChanged: (color) {
                              setState(() {
                                _pickerColor = color;
                                _colorValue = color.value;
                              });
                              Navigator.pop(context);
                            },
                            availableColors: lightPastelColors,
                          ),
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColor.mainBrown.of(context),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('닫기'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(_colorValue ?? _pickerColor.value),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '카테고리명을 입력하세요.',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                floatingLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF007AFF),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              style: TextStyle(
                color: AppColor.deepBlack.of(context),
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.gray30.of(context),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.primaryBlue.of(context),
          ),
          onPressed: () {
            if (_nameController.text.isNotEmpty && _colorValue != null) {
              Navigator.of(context, rootNavigator: true).pop(
                SubscriptionCategory(
                  name: _nameController.text,
                  colorValue: _colorValue,
                ),
              );
            }
          },
          child: const Text('추가'),
        ),
      ],
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
                        child: method.logoUrl != null
                            ? Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: ClipOval(
                                  child: Image.asset(
                                    method.logoUrl!,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.credit_card,
                                color: AppColor.mainBrown.of(context),
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
