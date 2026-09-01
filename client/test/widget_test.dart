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
    expect(find.text('Login'), findsNWidgets(2));

    await tester.tap(find.text('New user? Register'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsNWidgets(2));
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Store number'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pins every post category to the physical right edge', (
    tester,
  ) async {
    const listing = Listing(
      'Construction helpers needed',
      'Need Worker',
      r'$85 / day',
      '0101',
      'Need four reliable helpers for loading materials.',
      'Ahmed Khan',
      '+966501234567',
      'Today, 9:30 AM',
      2026,
      9,
      1,
      Icons.engineering,
      Colors.white,
    );
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 900, height: 390, child: ListingCard(listing: listing)),
      ),
    ));

    final categoryRight = tester.getTopRight(
      find.byKey(const Key('post-category-right')),
    ).dx;
    final timeRight = tester.getTopRight(
      find.byKey(const Key('post-time-left')),
    ).dx;
    final cardRight = tester.getTopRight(find.byType(Card)).dx;
    expect(categoryRight, greaterThan(timeRight));
    expect(cardRight - categoryRight, lessThan(20));
  });
}
