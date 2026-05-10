import 'package:flutter_test/flutter_test.dart';
import 'package:kitepay/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KitePayApp());
    expect(find.byType(KitePayApp), findsOneWidget);
  });
}
