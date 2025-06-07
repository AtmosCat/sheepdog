import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/widgets/light_pastel_colors.dart';

class CategoryAddDialog extends StatefulWidget {
  const CategoryAddDialog({Key? key}) : super(key: key);

  @override
  State<CategoryAddDialog> createState() => _CategoryAddDialogState();
}

class _CategoryAddDialogState extends State<CategoryAddDialog> {
  final _nameController = TextEditingController();
  int? _colorValue;
  Color _pickerColor = const Color(0xFFA2E2FF);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.containerWhite.of(context),
      title: Row(
        children: [
          Text(
            '카테고리 추가',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColor.deepBlack.of(context),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: AppColor.containerWhite.of(context),
                    title: Text(
                      '컬러 선택',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColor.deepBlack.of(context),
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: BlockPicker(
                        pickerColor: _pickerColor,
                        onColorChanged: (color) {
                          setState(() {
                            _pickerColor = color;
                            _colorValue = color.value;
                          });
                          Navigator.pop(context);
                        },
                        availableColors: lightPastelColors,
                      ),
                    ),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColor.mainBrown.of(context),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('닫기'),
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Color(_colorValue ?? _pickerColor.value),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '카테고리명을 입력하세요.',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                floatingLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF007AFF),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              style: TextStyle(
                color: AppColor.deepBlack.of(context),
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.gray30.of(context),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.primaryBlue.of(context),
          ),
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                (_colorValue ?? _pickerColor.value) != null) {
              Navigator.of(context, rootNavigator: true).pop(
                SubscriptionCategory(
                  name: _nameController.text,
                  colorValue: _colorValue ?? _pickerColor.value,
                ),
              );
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
