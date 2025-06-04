import 'package:flutter/material.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/subscription_service_repository.dart';

class SubscriptionServiceViewModel extends ChangeNotifier {
  final SubscriptionServiceRepository _repository = SubscriptionServiceRepository();

  List<SubscriptionService> _services = [];
  List<SubscriptionService> get services => _services;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();
    _services = await _repository.getAllServices();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addService(SubscriptionService service) async {
    await _repository.addService(service);
    await loadServices();
  }

  Future<void> updateService(SubscriptionService service) async {
    await _repository.updateService(service);
    await loadServices();
  }

  Future<void> deleteService(String id) async {
    await _repository.deleteService(id);
    await loadServices();
  }

  Future<SubscriptionService?> getServiceById(String id) async {
    return await _repository.getServiceById(id);
  }
}