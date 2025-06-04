import 'package:flutter/material.dart';
import 'package:sheepdog/data/model/payment_method.dart';
import 'package:sheepdog/data/repository/payment_method_repository.dart';

class PaymentMethodViewModel extends ChangeNotifier {
  final PaymentMethodRepository _repository = PaymentMethodRepository();

  List<PaymentMethod> _methods = [];
  List<PaymentMethod> get methods => _methods;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadMethods() async {
    _isLoading = true;
    notifyListeners();
    _methods = await _repository.getAllMethods();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMethod(PaymentMethod method) async {
    await _repository.addMethod(method);
    await loadMethods();
  }

  Future<void> updateMethod(PaymentMethod method) async {
    await _repository.updateMethod(method);
    await loadMethods();
  }

  Future<void> deleteMethod(String id) async {
    await _repository.deleteMethod(id);
    await loadMethods();
  }

  Future<PaymentMethod?> getMethodById(String id) async {
    return await _repository.getMethodById(id);
  }
}