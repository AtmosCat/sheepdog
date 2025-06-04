import 'models.dart';
import 'patent_api_service.dart';
import 'package:sheepdog/data/repository/sql_database.dart';
import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sqflite/sqflite.dart';

class BrandRepository {
  final PatentApiService _apiService = PatentApiService();

  // 검색 결과 캐시
  final Map<String, List<BrandSearchResult>> _searchCache = {};

  // 브랜드명으로 상표 검색
  Future<List<BrandSearchResult>> searchBrands(String query) async {
    if (_searchCache.containsKey(query)) {
      return _searchCache[query]!;
    }
    final results = await _apiService.searchBrand(query);
    _searchCache[query] = results;
    return results;
  }

  // 출원번호로 브랜드 이미지 URL 조회
  Future<String?> fetchBrandImageUrl(String applicationNumber) async {
    final BrandImageResult? imageResult = await _apiService.fetchBrandImage(applicationNumber);
    return imageResult?.path;
  }

  // 구독 서비스 정보를 내부 DB에 저장
  Future<void> saveSubscriptionService(SubscriptionService service) async {
    final db = await SqlDatabase.instance.database;
    await db.insert(
      'subscription_services',
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
