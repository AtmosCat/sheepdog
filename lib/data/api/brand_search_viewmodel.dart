import 'package:flutter/material.dart';
import 'package:sheepdog/data/api/brand_repository.dart';
import 'models.dart';

class BrandSearchViewModel extends ChangeNotifier {
  final BrandRepository _repository = BrandRepository();

  List<BrandSearchResult> _searchResults = [];
  List<BrandSearchResult> get searchResults => _searchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> searchBrands() async {
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await _repository.searchBrands(_searchQuery);
      _searchResults = results;
    } catch (e) {
      _searchResults = [];
      _errorMessage = '검색 중 오류가 발생했습니다.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<BrandImageResult?> fetchBrandImage(String applicationNumber) async {
    try {
      final String? imageUrl = await _repository.fetchBrandImageUrl(
        applicationNumber,
      );
      if (imageUrl == null) return null;
      return BrandImageResult(imageName: '', path: imageUrl, smallPath: null);
    } catch (e) {
      return null;
    }
  }

  void clear() {
    _searchQuery = '';
    _searchResults = [];
    _errorMessage = null;
    notifyListeners();
  }
}

class SelectedBrandViewModel extends ChangeNotifier {
  BrandSearchResult? _selectedBrand;
  BrandSearchResult? get selectedBrand => _selectedBrand;

  void selectBrand(BrandSearchResult brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  void clear() {
    _selectedBrand = null;
    notifyListeners();
  }
}
