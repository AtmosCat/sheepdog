import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // 컬러 팔레트용
import 'package:intl/intl.dart';
import 'package:sheepdog/data/api/brand_repository.dart';
import 'package:sheepdog/data/api/models.dart';
import 'package:sheepdog/data/api/service_select_dialog.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/payment_method.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/ui/pages/subscription_add/widgets/light_pastel_colors.dart';

class SubscriptionAddPage extends StatefulWidget {
  const SubscriptionAddPage({Key? key}) : super(key: key);

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
    _loadData();
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
    final selected = await showDialog<BrandSearchResult>(
      context: context,
      builder: (context) {
        return ServiceSelectDialog(
          onSelected: (brand) {
            Navigator.pop(context, brand);
          },
        );
      },
    );

    if (selected != null) {
      String? logoUrl;
      try {
        logoUrl = await BrandRepository().fetchBrandImageUrl(
          selected.applicationNumber,
        );
      } catch (_) {
        logoUrl = null;
      }

      setState(() {
        _selectedService = SubscriptionService(
          name: selected.indexNo, // 브랜드명에 해당하는 값으로 수정
          logoUrl: logoUrl,
          categoryId: '', // 카테고리 ID는 별도 선택
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
    if (result != null) setState(() => _selectedCycle = result);
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
                fontSize: 15,
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
                hintText: '금액을 입력하세요',
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
          onAdd: () {
            // 결제수단 추가 다이얼로그 (추후 구현)
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

    final service = SubscriptionService(
      name: _selectedService!.name,
      logoUrl: _selectedService!.logoUrl,
      categoryId: _selectedCategory!.id,
      paymentCycle: _selectedCycle,
      paymentDate: _getPaymentDate(),
      paymentAmount: _selectedAmount,
      paymentMethodId: _selectedMethod!.id,
      memo: _memo,
    );
    await _serviceRepo.addService(service);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('구독이 추가되었습니다.')));
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
    // 주 단위 등은 별도 로직 필요
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
        title: const Text('구독 추가'),
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
                        CircleAvatar(
                          backgroundImage: _selectedService!.logoUrl != null
                              ? NetworkImage(_selectedService!.logoUrl!)
                              : null,
                          backgroundColor: AppColor.mainYellowLight3.of(
                            context,
                          ),
                          radius: 16,
                          child: _selectedService!.logoUrl == null
                              ? Icon(
                                  Icons.apps,
                                  color: AppColor.mainBrown.of(context),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(_selectedService!.name),
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
                          backgroundImage: _selectedMethod!.logoUrl != null
                              ? NetworkImage(_selectedMethod!.logoUrl!)
                              : null,
                          backgroundColor: AppColor.mainYellowLight3.of(
                            context,
                          ),
                          radius: 18, // 기존 13 -> 18로 증가
                          child: _selectedMethod!.logoUrl == null
                              ? Icon(
                                  Icons.credit_card,
                                  color: AppColor.mainBrown.of(context),
                                  size: 22, // 기존 16 -> 22로 증가
                                )
                              : null,
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
              label: const Text(
                '저장하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
      title: Text(
        '카테고리 추가',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AppColor.deepBlack.of(context),
        ),
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
                labelText: '카테고리명',
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
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

          const SizedBox(height: 12),
          Row(
            children: [
              const Text('컬러: '),
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
                  width: 24,
                  height: 24,
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
                    (method) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: method.logoUrl != null
                              ? NetworkImage(method.logoUrl!)
                              : null,
                          backgroundColor: AppColor.mainYellowLight3.of(
                            context,
                          ),
                          child: method.logoUrl == null
                              ? Icon(
                                  Icons.credit_card,
                                  color: AppColor.mainBrown.of(context),
                                )
                              : null,
                        ),
                        title: Text(
                          method.serviceName ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          method.alias,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(method);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
