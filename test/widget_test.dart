import 'package:flutter_test/flutter_test.dart';
import 'package:sheepdog/main.dart';

void main() {
  testWidgets('앱이 빌드된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(showStartupAd: false));
    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
  });
}
