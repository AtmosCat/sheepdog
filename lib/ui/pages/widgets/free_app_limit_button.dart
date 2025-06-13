import 'package:flutter/material.dart';
import 'package:sheepdog/theme/colors.dart';

class FreeAppLimitButton extends StatelessWidget {
  final int currentCount;
  final int limit;
  final Future<void> Function() onAdd;
  final Future<void> Function()? onReload;
  final BuildContext parentContext;

  const FreeAppLimitButton({
    super.key,
    required this.currentCount,
    this.limit = 5,
    required this.onAdd,
    this.onReload,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: FloatingActionButton.extended(
        backgroundColor: AppColor.mainYellow.of(context),
        foregroundColor: AppColor.deepBlack.of(context),
        icon: const Icon(Icons.add),
        label: const Text(
          '구독 추가',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: () async {
          if (currentCount >= limit) {
            showDialog(
              context: parentContext,
              barrierDismissible: true,
              builder: (dialogContext) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  backgroundColor: AppColor.containerWhite.of(context),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          '무료 앱 구독 한도 도달',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          '현재는 구독을 최대 5개까지만 추가할 수 있어요.\n단 한 번의 결제를 통해 다양한 혜택을 누려보세요!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '• 개수 제한 없이 구독 추가하기',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.left,
                            ),
                            SizedBox(height: 6),
                            Text(
                              '• 더 다양한 이모지로 나만의 구독 꾸미기',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.left,
                            ),
                            SizedBox(height: 6),
                            Text(
                              '• 광고 없이 편하게 앱 이용하기',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.mainYellow.of(context),
                              foregroundColor: AppColor.deepBlack.of(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () {
                              // launchUrlString('YOUR_LINK_HERE');
                            },
                            child: const Text('단 한 번 결제하기'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              child: Text(
                                "닫기",
                                style: TextStyle(
                                  color: AppColor.lightGray20.of(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
            return;
          }
          await onAdd();
          if (onReload != null) await onReload!();
        },
      ),
    );
  }
}
