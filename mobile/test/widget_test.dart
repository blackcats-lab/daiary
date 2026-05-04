import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiary/config/theme.dart';

void main() {
  testWidgets('DaiaryTheme.light builds without throwing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DaiaryTheme.light(),
        home: const Scaffold(body: Center(child: Text('dAIary'))),
      ),
    );
    expect(find.text('dAIary'), findsOneWidget);
  });

  test('Brand colors are defined', () {
    expect(DaiaryColors.brandGold, const Color(0xFFC4956A));
    expect(DaiaryColors.deepBrown, const Color(0xFF2D2420));
    expect(DaiaryColors.cream, const Color(0xFFF5EFE8));
    expect(DaiaryColors.warmAccent, const Color(0xFFE8A87C));
  });
}
