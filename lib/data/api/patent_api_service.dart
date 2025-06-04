import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sheepdog/data/api/models.dart';
import 'package:xml2json/xml2json.dart';

class PatentApiService {
  // 실제 발급받은 서비스키로 교체 필요
  static const String _serviceKey = 'YlgP80NwhNBwLETbohJrUha7ygmEO09Y35mxU%2Fuyz0N90%2BHesPbErivbWW5%2F8bp6aNZxNP8HwPo9WokX3r6O8w%3D%3D';
  static const String _searchUrl = 'http://kipo-api.kipi.or.kr/openapi/service/trademarkInfoSearchService/getWordSearch';
  static const String _imageUrl = 'http://kipo-api.kipi.or.kr/openapi/service/trademarkInfoSearchService/getSampleImageInfoSearch';

  Future<List<BrandSearchResult>> searchBrand(String query, {int recentYear = 0}) async {
    final url = '$_searchUrl?serviceKey=$_serviceKey&searchString=$query&searchRecentYear=$recentYear';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // 반드시 UTF-8로 디코딩!
      final xml = utf8.decode(response.bodyBytes);
      final xml2json = Xml2Json();
      xml2json.parse(xml);
      final jsonStr = xml2json.toParker();
      final json = jsonDecode(jsonStr);

      final items = json['response']?['body']?['items']?['item'];
      if (items == null) return [];
      if (items is List) {
        return items.map<BrandSearchResult>((item) => BrandSearchResult(
          indexNo: item['indexNo'] ?? '',
          applicationNumber: item['applicationNumber'] ?? '',
          applicantName: item['applicantName'] ?? '',
          regPrivilegeName: item['regPrivilegeName'] ?? '',
        )).toList();
      } else if (items is Map) {
        return [BrandSearchResult(
          indexNo: items['indexNo'] ?? '',
          applicationNumber: items['applicationNumber'] ?? '',
          applicantName: items['applicantName'] ?? '',
          regPrivilegeName: items['regPrivilegeName'] ?? '',
        )];
      }
      return [];
    } else {
      throw Exception('브랜드 검색 실패: ${response.statusCode}');
    }
  }

  Future<BrandImageResult?> fetchBrandImage(String applicationNumber) async {
    final url = '$_imageUrl?serviceKey=$_serviceKey&applicationNumber=$applicationNumber';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // 반드시 UTF-8로 디코딩!
      final xml = utf8.decode(response.bodyBytes);
      final xml2json = Xml2Json();
      xml2json.parse(xml);
      final jsonStr = xml2json.toParker();
      final json = jsonDecode(jsonStr);

      final items = json['response']?['body']?['items']?['item'];
      if (items == null) return null;
      return BrandImageResult(
        imageName: items['imageName'] ?? '',
        path: items['path'] ?? '',
        smallPath: items['smallPath'],
      );
    } else {
      throw Exception('이미지 검색 실패: ${response.statusCode}');
    }
  }
}
