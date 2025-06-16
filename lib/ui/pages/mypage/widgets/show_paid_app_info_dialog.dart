import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/data/viewmodel/user_info_viewmodel.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/pages/mypage/widgets/purchase_premium.dart';

void showPaidAppInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: AppColor.containerWhite.of(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                '유료 앱 안내',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 18),
              const Text(
                '단 한 번 결제를 통해 다양한 유료 앱 혜택을 누려보세요!',
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
                    '1. 광고 없이 편리한 앱 사용',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 6),
                  Text(
                    '2. 300종 이상의 다양한 구독 이모지',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 6),
                  Text(
                    '3. 카테고리별로 보기 쉽게 분류된 구독 이모지',
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
                  onPressed: () async {
                    final isPremium =
                        Provider.of<UserInfoViewModel>(
                          context,
                          listen: false,
                        ).userInfo?.isPremium ??
                        false;
                    await purchasePremium(context, isPremium: isPremium);
                  },
                  child: const Text('단 한 번 1,900원 결제하기'),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
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
}
