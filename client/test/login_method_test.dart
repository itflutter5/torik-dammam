import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrap_market/main.dart';

void main() {
  testWidgets('login defaults to email and lets users switch to phone', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PasswordAccessPage()));
    final emailField = find.byKey(const Key('login-email'));
    expect(emailField, findsOneWidget);
    expect(find.widgetWithText(TextField, 'Saudi phone number'), findsNothing);
    await tester.enterText(emailField, 'person@example.com');

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    expect(emailField, findsNothing);
    final phoneField = find.widgetWithText(TextField, 'Saudi phone number');
    expect(phoneField, findsOneWidget);
    await tester.enterText(phoneField, '+966512345678');

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(emailField).controller!.text, 'person@example.com');
    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(phoneField).controller!.text, '+966512345678');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('registration continues to request both email and phone', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PasswordAccessPage(registrationMode: true),
    ));
    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.widgetWithText(TextField, 'Email address *'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Saudi phone number *'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
