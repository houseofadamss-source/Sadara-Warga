import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadarawarga/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SadaraApp(isLoggedIn: false));

    // Verify that our app starts.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
