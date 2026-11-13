import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:property_valuer_pro/app/app.dart';

void main() {
  testWidgets('Dashboard UI smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const PropertyValuerProApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Property Valuer Pro'), findsWidgets);
  });
}
