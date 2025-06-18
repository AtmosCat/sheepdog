import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';

Future<void> purchasePremium(
  BuildContext context, {
  required bool isPremium,
}) async {
  if (isPremium) {
    SnackbarUtil.showToastMessage('이미 결제가 완료되었습니다.');
    return;
  }

  const String androidProductId = 'premium_android';
  const String iosProductId = 'premium_ios';

  final InAppPurchase iap = InAppPurchase.instance;
  final bool available = await iap.isAvailable();
  if (!available) {
    SnackbarUtil.showToastMessage('결제 서비스를 사용할 수 없습니다.');
    return;
  }

  final String productId = Platform.isIOS ? iosProductId : androidProductId;

  // 상품 정보 가져오기
  final ProductDetailsResponse response = await iap.queryProductDetails({
    productId,
  });
  if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
    SnackbarUtil.showToastMessage('상품 정보를 불러올 수 없습니다.');
    return;
  }
  final ProductDetails productDetails = response.productDetails.first;

  // 결제 요청
  final PurchaseParam purchaseParam = PurchaseParam(
    productDetails: productDetails,
  );
  iap.buyNonConsumable(purchaseParam: purchaseParam);

  // 결제 결과 리스너
  final Stream<List<PurchaseDetails>> purchaseUpdated = iap.purchaseStream;
  late StreamSubscription<List<PurchaseDetails>> subscription;

  subscription = purchaseUpdated.listen((purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == productId &&
          purchase.status == PurchaseStatus.purchased) {
        SnackbarUtil.showToastMessage('결제가 완료되었습니다! 감사합니다.');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'isPremium': true});
        }
        await subscription.cancel();
      } else if (purchase.status == PurchaseStatus.error) {
        SnackbarUtil.showToastMessage('결제 중 오류가 발생했습니다.');
        await subscription.cancel();
      }
    }
  });
}
