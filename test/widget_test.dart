import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:property_valuer_pro/app/app.dart';

void main() {
  testWidgets('Dashboard UI smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const PropertyValuerProApp());
    await tester.pumpAndSettle();

    expect(find.text('Property Valuer Pro'), findsWidgets);
    expect(find.text('+ Create New Valuation'), findsOneWidget);
  });
}
