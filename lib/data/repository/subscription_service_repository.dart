import 'package:sheepdog/data/dao/subscription_service_dao.dart';
import 'package:sheepdog/data/model/subscription_service.dart';

class SubscriptionServiceRepository {
  final SubscriptionServiceDao _dao = SubscriptionServiceDao();

  Future<int> addService(SubscriptionService service) async {
    return await _dao.insert(service);
  }

  Future<int> updateService(SubscriptionService service) async {
    return await _dao.update(service);
  }

  Future<int> deleteService(String id) async {
    return await _dao.delete(id);
  }

  Future<SubscriptionService?> getServiceById(String id) async {
    return await _dao.getById(id);
  }

  Future<List<SubscriptionService>> getAllServices() async {
    return await _dao.getAll();
  }
}