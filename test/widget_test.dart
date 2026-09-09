import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sheepdog/data/premium/premium_controller.dart';
import 'package:sheepdog/main.dart';

void main() {
  testWidgets('앱이 빌드된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PremiumController(),
        child: const MyApp(showStartupAd: false),
      ),
    );
    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
  });
}
