import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitepay_app_2026/main.dart'; // Ensure this matches your package name

void main() {
  testWidgets('Counter increment smoke test', (WidgetTester tester) async {
    // FIXED: Changed 'MyApp' to 'KitePayApp'
    await tester.pumpWidget(const KitePayApp());

    // Verify that our app starts (you can update these tests later)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
