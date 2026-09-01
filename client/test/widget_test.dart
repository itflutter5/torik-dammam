import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrap_market/main.dart';

void main() {
  testWidgets('shows public home and opens login from Post', (tester) async {
    await tester.pumpWidget(const ScrapMarketApp());
    expect(find.text('Torik-Dammam Scrap Market'), findsOneWidget);
    expect(find.text('Post'), findsOneWidget);

    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(find.text('Login / Sign up'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
