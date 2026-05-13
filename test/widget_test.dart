import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge/core/theme/app_theme.dart';

void main() {
  testWidgets('Light theme builds without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Center(child: Text('FitForge'))),
      ),
    );
    expect(find.text('FitForge'), findsOneWidget);
  });

  testWidgets('Dark theme builds without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: Center(child: Text('FitForge'))),
      ),
    );
    expect(find.text('FitForge'), findsOneWidget);
  });
}
