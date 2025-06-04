import 'package:sheepdog/data/dao/subscription_category_dao.dart';
import 'package:sheepdog/data/model/subscription_category.dart';

class SubscriptionCategoryRepository {
  final SubscriptionCategoryDao _dao = SubscriptionCategoryDao();

  Future<int> addCategory(SubscriptionCategory category) async {
    return await _dao.insert(category);
  }

  Future<int> updateCategory(SubscriptionCategory category) async {
    return await _dao.update(category);
  }

  Future<int> deleteCategory(String id) async {
    return await _dao.delete(id);
  }

  Future<SubscriptionCategory?> getCategoryById(String id) async {
    return await _dao.getById(id);
  }

  Future<List<SubscriptionCategory>> getAllCategories() async {
    return await _dao.getAll();
  }
}