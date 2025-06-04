import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/data/api/brand_search_viewmodel.dart';
import 'package:sheepdog/data/api/models.dart';
import 'package:sheepdog/data/api/brand_repository.dart';
import 'package:sheepdog/theme/colors.dart';

class ServiceSelectDialog extends StatefulWidget {
  final void Function(BrandSearchResult) onSelected;

  const ServiceSelectDialog({Key? key, required this.onSelected})
    : super(key: key);

  @override
  _ServiceSelectDialogState createState() => _ServiceSelectDialogState();
}

class _ServiceSelectDialogState extends State<ServiceSelectDialog> {
  late BrandSearchViewModel _viewModel;
  final BrandRepository _brandRepository = BrandRepository();

  @override
  void initState() {
    super.initState();
    _viewModel = BrandSearchViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BrandSearchViewModel>.value(
      value: _viewModel,
      child: Consumer<BrandSearchViewModel>(
        builder: (context, model, child) {
          return AlertDialog(
            backgroundColor: AppColor.containerWhite.of(context),
            title: Text(
              '브랜드 검색',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColor.deepBlack.of(context),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: '브랜드명을 입력하세요',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColor.mainYellow.of(context),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      model.updateSearchQuery(value);
                      model.searchBrands();
                    },
                    onTapOutside: (event) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                  const SizedBox(height: 12),
                  if (model.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (model.errorMessage != null)
                    Text(
                      model.errorMessage!,
                      style: TextStyle(color: AppColor.primaryRed.of(context)),
                    )
                  else if (model.searchResults.isEmpty)
                    const Text('검색 결과가 없습니다.')
                  else
                    SizedBox(
                      height: 260,
                      width: double.maxFinite,
                      child: ListView.builder(
                        itemCount: model.searchResults.length,
                        itemBuilder: (context, index) {
                          final item = model.searchResults[index];
                          return FutureBuilder<String?>(
                            future: _brandRepository.fetchBrandImageUrl(
                              item.applicationNumber,
                            ),
                            builder: (context, snapshot) {
                              final imageUrl = snapshot.data;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColor.mainYellowLight3.of(
                                    context,
                                  ),
                                  backgroundImage:
                                      (imageUrl != null && imageUrl.isNotEmpty)
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  child: (imageUrl == null || imageUrl.isEmpty)
                                      ? Icon(
                                          Icons.image_not_supported,
                                          color: AppColor.mainBrown.of(context),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  item.applicantName ??
                                      '브랜드명 없음', // brandName 필드가 반드시 있어야 함
                                  style: TextStyle(
                                    color: AppColor.deepBlack.of(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(item.regPrivilegeName ?? "없음"),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.mainBrown.of(context),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
            ],
          );
        },
      ),
    );
  }
}
