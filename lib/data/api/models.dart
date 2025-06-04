class BrandSearchResult {
  final String indexNo; // 번호
  final String applicationNumber; // 출원번호
  final String applicantName; // 출원번호
  final String regPrivilegeName; // 출원번호


  BrandSearchResult({
    required this.indexNo,
    required this.applicationNumber,
    required this.applicantName,
    required this.regPrivilegeName,
  });

  factory BrandSearchResult.fromJson(Map<String, dynamic> json) {
    return BrandSearchResult(
      indexNo: json['indexNo'] ?? '',
      applicationNumber: json['applicationNumber'] ?? '',
      applicantName: json['applicantName'] ?? '',
      regPrivilegeName: json['regPrivilegeName'] ?? '',
    );
  }
}

class BrandImageResult {
  final String imageName; // 이미지명
  final String path; // 이미지 경로
  final String? smallPath; // 작은 이미지 경로(옵션)

  BrandImageResult({
    required this.imageName,
    required this.path,
    this.smallPath,
  });

  factory BrandImageResult.fromJson(Map<String, dynamic> json) {
    return BrandImageResult(
      imageName: json['imageName'] ?? '',
      path: json['path'] ?? '',
      smallPath: json['smallPath'],
    );
  }
}
