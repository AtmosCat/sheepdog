import 'package:flutter/material.dart';
import 'package:sheepdog/data/model/payment_method.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/mypage/payment_method_detail_page.dart';
import 'package:sheepdog/ui/pages/widgets/add_payment_dialog.dart';
import 'package:sheepdog/ui/pages/widgets/payment_method_card.dart';
// PaymentMethodCard 위젯 import 필요

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  List<PaymentMethod> _methods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final repo = PaymentMethodRepository();
    final list = await repo.getAllMethods();
    setState(() {
      _methods = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 수단 관리'),
        centerTitle: true,
        backgroundColor: AppColor.containerWhite.of(context),
        foregroundColor: AppColor.deepBlack.of(context),
        elevation: 0,
      ),
      backgroundColor: AppColor.containerWhite.of(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _methods.isEmpty
          ? Center(
              child: Text(
                '등록된 결제 수단이 없습니다.',
                style: TextStyle(
                  color: AppColor.gray30.of(context),
                  fontSize: 15,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              itemCount: _methods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, idx) {
                final paymentMethod = _methods[idx];
                return PaymentMethodCard(
                  logoUrl: paymentMethod.logoUrl,
                  serviceName: paymentMethod.serviceName,
                  alias: paymentMethod.alias,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentMethodDetailPage(
                          paymentMethod: paymentMethod,
                        ),
                      ),
                    );
                    await _loadMethods();
                  },
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 32), // 아래에서 띄움
        child: FloatingActionButton.extended(
          backgroundColor: AppColor.mainYellow.of(context),
          foregroundColor: AppColor.deepBlack.of(context),
          icon: const Icon(Icons.add),
          label: const Text('결제 수단 추가', style: TextStyle(fontSize: 14)),
          onPressed: () async {
            final newMethod = await showDialog(
              context: context,
              builder: (_) => const AddPaymentMethodDialog(),
            );
            if (newMethod != null) {
              await _loadMethods();
            }
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
