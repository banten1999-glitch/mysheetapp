// Basic smoke test: the app boots and shows the splash/login flow without
// throwing, without requiring any real Google account or network access.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mysheetapp/app.dart';

void main() {
  testWidgets('App boots and renders a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HasnawiLedgerApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
