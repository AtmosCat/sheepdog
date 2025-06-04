import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/model/payment_method.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';
import 'package:sheepdog/theme/colors.dart';

class TestDataInputPage extends StatefulWidget {
  const TestDataInputPage({Key? key}) : super(key: key);

  @override
  State<TestDataInputPage> createState() => _TestDataInputPageState();
}

class _TestDataInputPageState extends State<TestDataInputPage> {
  // Service
  final _serviceNameController = TextEditingController();
  final _serviceLogoController = TextEditingController();
  final _serviceCategoryIdController = TextEditingController();
  PaymentCycle? _paymentCycle;
  DateTime? _paymentDate;
  final _paymentAmountController = TextEditingController();
  final _paymentMethodIdController = TextEditingController();
  final _serviceMemoController = TextEditingController();

  // Category
  final _categoryNameController = TextEditingController();
  int? _categoryColorValue;

  // Payment Method
  final _methodServiceNameController = TextEditingController();
  final _methodAliasController = TextEditingController();
  final _methodMemoController = TextEditingController();

  final _serviceRepo = SubscriptionServiceRepository();
  final _categoryRepo = SubscriptionCategoryRepository();
  final _methodRepo = PaymentMethodRepository();

  void _saveService() async {
    final service = SubscriptionService(
      name: _serviceNameController.text,
      logoUrl: _serviceLogoController.text.isEmpty ? null : _serviceLogoController.text,
      categoryId: _serviceCategoryIdController.text,
      paymentCycle: _paymentCycle,
      paymentDate: _paymentDate,
      paymentAmount: int.tryParse(_paymentAmountController.text),
      paymentMethodId: _paymentMethodIdController.text,
      memo: _serviceMemoController.text,
    );
    await _serviceRepo.addService(service);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('구독 서비스 저장 완료')),
    );
  }

  void _saveCategory() async {
    final category = SubscriptionCategory(
      name: _categoryNameController.text,
      colorValue: _categoryColorValue,
    );
    await _categoryRepo.addCategory(category);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('카테고리 저장 완료')),
    );
  }

  void _saveMethod() async {
    final method = PaymentMethod(
      serviceName: _methodServiceNameController.text.isEmpty ? null : _methodServiceNameController.text,
      alias: _methodAliasController.text,
      memo: _methodMemoController.text,
    );
    await _methodRepo.addMethod(method);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('결제 수단 저장 완료')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('테스트 데이터 입력'),
        backgroundColor: AppColor.mainYellow.of(context),
        foregroundColor: AppColor.deepBlack.of(context),
      ),
      backgroundColor: AppColor.containerWhite.of(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 구독 서비스 입력
            Text('구독 서비스', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _buildTextField(_serviceNameController, '서비스명'),
            _buildTextField(_serviceLogoController, '로고 이미지 URL'),
            _buildTextField(_serviceCategoryIdController, '카테고리 ID'),
            DropdownButtonFormField<PaymentCycle>(
              value: _paymentCycle,
              decoration: const InputDecoration(labelText: '결제 주기'),
              items: PaymentCycle.values.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e.name),
                );
              }).toList(),
              onChanged: (v) => setState(() => _paymentCycle = v),
            ),
            Row(
              children: [
                Text(_paymentDate == null
                    ? '결제일: 미선택'
                    : '결제일: ${DateFormat('yyyy-MM-dd').format(_paymentDate!)}'),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.mainYellow.of(context),
                    foregroundColor: AppColor.deepBlack.of(context),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _paymentDate = picked);
                  },
                  child: const Text('날짜 선택'),
                ),
              ],
            ),
            _buildTextField(_paymentAmountController, '결제 금액', keyboardType: TextInputType.number),
            _buildTextField(_paymentMethodIdController, '결제 수단 ID'),
            _buildTextField(_serviceMemoController, '메모'),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.mainYellow.of(context),
                foregroundColor: AppColor.deepBlack.of(context),
              ),
              onPressed: _saveService,
              child: const Text('구독 서비스 저장'),
            ),
            const Divider(height: 32),
            // 카테고리 입력
            Text('구독 카테고리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _buildTextField(_categoryNameController, '카테고리명'),
            Row(
              children: [
                Text('컬러값: ${_categoryColorValue ?? '미선택'}'),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.mainYellow.of(context),
                    foregroundColor: AppColor.deepBlack.of(context),
                  ),
                  onPressed: () async {
                    // 간단하게 기본 색상값 선택
                    setState(() => _categoryColorValue = Colors.blue.value);
                  },
                  child: const Text('컬러 선택'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.mainYellow.of(context),
                foregroundColor: AppColor.deepBlack.of(context),
              ),
              onPressed: _saveCategory,
              child: const Text('카테고리 저장'),
            ),
            const Divider(height: 32),
            // 결제 수단 입력
            Text('결제 수단', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _buildTextField(_methodServiceNameController, '결제서비스명'),
            _buildTextField(_methodAliasController, '별칭'),
            _buildTextField(_methodMemoController, '메모'),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.mainYellow.of(context),
                foregroundColor: AppColor.deepBlack.of(context),
              ),
              onPressed: _saveMethod,
              child: const Text('결제 수단 저장'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColor.containerLightGray10.of(context),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        keyboardType: keyboardType,
      ),
    );
  }
}