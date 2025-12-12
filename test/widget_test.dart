import 'package:flutter_test/flutter_test.dart';

import 'package:loan_calculator_web/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinancialCalculatorApp());

    // Verify that app title is displayed
    expect(find.text('財務計算工具'), findsWidgets);

    // Verify that both calculator options are available
    expect(find.text('貸款計算器'), findsOneWidget);
    expect(find.text('定投複利計算器'), findsOneWidget);
  });
}
