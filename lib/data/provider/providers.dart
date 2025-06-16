import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sheepdog/data/viewmodel/payment_method_viewmodel.dart';
import 'package:sheepdog/data/viewmodel/subscription_category_viewmodel.dart';
import 'package:sheepdog/data/viewmodel/subscription_service_viewmodel.dart';
import 'package:sheepdog/data/viewmodel/user_info_viewmodel.dart';

// 구독 서비스 ViewModel Provider
final subscriptionServiceProvider =
    ChangeNotifierProvider<SubscriptionServiceViewModel>(
      create: (_) => SubscriptionServiceViewModel(),
    );

// 구독 카테고리 ViewModel Provider
final subscriptionCategoryProvider =
    ChangeNotifierProvider<SubscriptionCategoryViewModel>(
      create: (_) => SubscriptionCategoryViewModel(),
    );

// 결제 수단 ViewModel Provider
final paymentMethodProvider = ChangeNotifierProvider<PaymentMethodViewModel>(
  create: (_) => PaymentMethodViewModel(),
);

final userInfoProvider = ChangeNotifierProvider<UserInfoViewModel>(
  create: (_) => UserInfoViewModel(),
);

// 앱 전체에서 사용할 경우 MultiProvider로 묶어서 사용할 수 있습니다.
final List<SingleChildWidget> appProviders = [
  subscriptionServiceProvider,
  subscriptionCategoryProvider,
  paymentMethodProvider,
  userInfoProvider
];
