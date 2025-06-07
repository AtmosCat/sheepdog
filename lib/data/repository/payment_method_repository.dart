import 'package:sheepdog/data/dao/payment_method_dao.dart';
import 'package:sheepdog/data/model/payment_method.dart';

class PaymentMethodRepository {
  final PaymentMethodDao _dao = PaymentMethodDao();

  Future<int> addMethod(PaymentMethod method) async {
    return await _dao.insert(method);
  }

  Future<int> updateMethod(PaymentMethod method) async {
    return await _dao.update(method);
  }

  Future<int> deleteMethod(String id) async {
    return await _dao.delete(id);
  }

  Future<PaymentMethod?> getMethodById(String? id) async {
    return await _dao.getById(id);
  }

  Future<List<PaymentMethod>> getAllMethods() async {
    return await _dao.getAll();
  }
}
