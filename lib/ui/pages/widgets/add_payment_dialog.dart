import 'package:flutter/material.dart';
import 'package:sheepdog/data/model/payment_method.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';

class AddPaymentMethodDialog extends StatefulWidget {
  const AddPaymentMethodDialog({Key? key}) : super(key: key);

  @override
  State<AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<AddPaymentMethodDialog> {
  String _selectedCategory = '은행';
  String? _selectedId;
  String _alias = '';
  bool _manualInput = false;
  String _manualBankName = '';

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

  final List<String> bankNames = [
    '경남은행',
    '광주은행',
    '국민은행',
    '부산은행',
    '수협은행',
    '수협중앙회',
    '신한은행',
    '신협',
    '씨티은행',
    '우리은행',
    '우체국',
    '전북은행',
    '제주은행',
    '지역농협',
    '카카오뱅크',
    '케이뱅크',
    '토스뱅크',
    '하나은행',
    '한국수출입은행',
    'IBK기업은행',
    'IM뱅크',
    'KDB산업은행',
    'MG새마을금고',
    'NH농협은행',
    'SBI저축은행',
    'SC제일은행',
  ];

  final List<String> cardNames = [
    '경남은행카드',
    '광주은행카드',
    '국민카드',
    '롯데카드',
    '부산은행카드',
    '삼성카드',
    '수협카드',
    '신한카드',
    '신협카드',
    '씨티은행카드',
    '우리카드',
    '우체국카드',
    '전북은행카드',
    '제주은행카드',
    '카카오뱅크카드',
    '케이뱅크카드',
    '토스뱅크카드',
    '하나카드',
    '현대카드',
    'BC카드',
    'IBK기업은행카드',
    'IM뱅크카드',
    'KDB산업은행카드',
    'MG새마을금고카드',
    'NH농협카드',
    'SC제일은행카드',
  ];

  final List<String> payNames = [
    '네이버페이',
    '스마일페이',
    '카카오페이',
    '쿠페이',
    '토스페이',
    '페이코',
    'SSG페이',
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> methods = _selectedCategory == '은행'
        ? bankNames
        : _selectedCategory == '카드'
        ? cardNames
        : payNames;
    return AlertDialog(
      backgroundColor: AppColor.containerWhite.of(context),
      title: Row(
        children: [
          const Text(
            '결제 수단 추가',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Spacer(),
          Row(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  unselectedWidgetColor: AppColor.mainYellow.of(context),
                ),
                child: Checkbox(
                  activeColor: AppColor.mainYellow.of(context),
                  value: _manualInput,
                  onChanged: (v) {
                    setState(() {
                      _manualInput = v ?? false;
                      if (!_manualInput) _manualBankName = '';
                    });
                  },
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Text('직접입력', style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
      content: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 360,
        height: _manualInput ? 180 : 480, // 다이얼로그 크기 자동 조절
        child: Column(
          children: [
            if (!_manualInput) ...[
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
              Expanded(
                child: ListView.builder(
                  itemCount: methods.length,
                  itemBuilder: (context, idx) {
                    final name = methods[idx];
                    final isSelected = _selectedId == name;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: Icon(
                          Icons.credit_card,
                          color: AppColor.mainYellow.of(context),
                        ),
                      ),
                      title: Text(
                        name,
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
                        setState(() => _selectedId = name);
                      },
                      selected: isSelected,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // 직접입력일 때만 표시
              TextField(
                decoration: const InputDecoration(
                  hintText: '금융기관 이름을 입력하세요.',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => _manualBankName = v,
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
              const SizedBox(height: 12),
            ],
            // 별명 입력란 (항상 표시)
            TextField(
              decoration: const InputDecoration(
                hintText: '별명을 입력하세요.',
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
          child: Text(
            '취소',
            style: TextStyle(color: AppColor.mainYellow.of(context)),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.primaryBlue.of(context),
          ),
          onPressed: () async {
            if (_manualInput) {
              if (_manualBankName.trim().isEmpty || _alias.trim().isEmpty) {
                SnackbarUtil.showToastMessage('금융기관 이름과 별명을 모두 입력해 주세요.');
                return;
              }
              final newMethod = PaymentMethod(
                serviceName: _manualBankName.trim(),
                logoUrl: null, // 로고 없음
                alias: _alias.trim(),
                memo: '',
                createdAt: DateTime.now(),
              );
              await PaymentMethodRepository().addMethod(newMethod);
              Navigator.pop(context, newMethod);
              SnackbarUtil.showToastMessage("결제 수단이 추가되었습니다.");
            } else {
              if (_selectedId == null || _alias.trim().isEmpty) {
                SnackbarUtil.showToastMessage('금융기관 이름과 별명을 모두 입력해 주세요.');
                return;
              }
              final newMethod = PaymentMethod(
                serviceName: _selectedId!,
                logoUrl: null,
                alias: _alias.trim(),
                memo: '',
                createdAt: DateTime.now(),
              );
              await PaymentMethodRepository().addMethod(newMethod);
              Navigator.pop(context, newMethod);
              SnackbarUtil.showToastMessage("결제 수단이 추가되었습니다.");
            }
          },

          child: Text(
            '저장',
            style: TextStyle(color: AppColor.defaultBlack.of(context)),
          ),
        ),
      ],
    );
  }
}
