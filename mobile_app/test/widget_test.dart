import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trader_ai/main.dart';

void main() {
  testWidgets('SmartTraderApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartTraderApp());

    // Verify that the title appears
    expect(find.text('Smart Trader AI'), findsWidgets);
  });
}
