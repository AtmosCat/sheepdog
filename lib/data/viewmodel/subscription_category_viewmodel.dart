import 'package:flutter/material.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';

class SubscriptionCategoryViewModel extends ChangeNotifier {
  final SubscriptionCategoryRepository _repository = SubscriptionCategoryRepository();

  List<SubscriptionCategory> _categories = [];
  List<SubscriptionCategory> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    _categories = await _repository.getAllCategories();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(SubscriptionCategory category) async {
    await _repository.addCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(SubscriptionCategory category) async {
    await _repository.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }

  Future<SubscriptionCategory?> getCategoryById(String id) async {
    return await _repository.getCategoryById(id);
  }
}