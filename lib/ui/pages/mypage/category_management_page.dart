import 'package:flutter/material.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/repository/subscription_category_repostory.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/widgets/category_add_dialog.dart';
import 'package:sheepdog/ui/pages/widgets/light_pastel_colors.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({Key? key}) : super(key: key);

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  List<SubscriptionCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final repo = SubscriptionCategoryRepository();
    final list = await repo.getAllCategories();
    setState(() {
      _categories = list;
      _loading = false;
    });
  }

  Future<void> _showAddDialog({SubscriptionCategory? origin}) async {
    final result = await showDialog<SubscriptionCategory>(
      context: context,
      builder: (_) => CategoryAddDialog(
        initialName: origin?.name,
        initialColor: origin != null
            ? Color(origin.colorValue ?? lightPastelColors.first.value)
            : null,
      ),
    );
    if (result != null) {
      final repo = SubscriptionCategoryRepository();
      if (origin == null) {
        await repo.addCategory(result);
        SnackbarUtil.showToastMessage('카테고리가 추가되었습니다.');
      } else {
        await repo.updateCategory(
          origin.copyWith(name: result.name, colorValue: result.colorValue),
        );
        SnackbarUtil.showToastMessage('카테고리가 수정되었습니다.');
      }
      await _loadCategories();
    }
  }

  Future<void> _showDeleteDialog(SubscriptionCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text('정말로 "${category.name}" 카테고리를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SubscriptionCategoryRepository().deleteCategory(category.id);
      SnackbarUtil.showToastMessage('카테고리가 삭제되었습니다.');
      await _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카테고리 관리'),
        centerTitle: true,
        backgroundColor: AppColor.containerWhite.of(context),
        foregroundColor: AppColor.deepBlack.of(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColor.deepBlack.of(context),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColor.containerWhite.of(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                ..._categories.map(
                  (cat) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        // 카테고리 칩
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(cat.colorValue ?? 0xFFA2E2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // 수정 버튼
                        Material(
                          color: Colors.transparent,
                          child: Ink(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            width: 44, // 원 크기 줄임
                            height: 44,
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                              ), // 아이콘 크기 줄임
                              splashRadius: 18, // 터치 효과 크기 줄임
                              padding: EdgeInsets.zero, // 패딩 최소화
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => _showAddDialog(origin: cat),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 삭제 버튼
                        Material(
                          color: Colors.transparent,
                          child: Ink(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            width: 44,
                            height: 44,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: AppColor.primaryRed.of(context),
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => _showDeleteDialog(cat),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_categories.isEmpty)
                  Center(
                    child: Text(
                      '등록된 카테고리가 없습니다.',
                      style: TextStyle(
                        color: AppColor.gray30.of(context),
                        fontSize: 15,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 32), // 아래에서 띄움
        child: FloatingActionButton.extended(
          backgroundColor: AppColor.mainYellow.of(context),
          foregroundColor: AppColor.deepBlack.of(context),
          icon: const Icon(Icons.add),
          label: const Text('카테고리 추가', style: TextStyle(fontSize: 14)),
          onPressed: () => _showAddDialog(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
