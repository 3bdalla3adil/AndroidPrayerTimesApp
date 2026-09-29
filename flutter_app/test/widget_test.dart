import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salawat_quran/app.dart';

void main() {
  setUp(() {
    // Mocks BOTH the legacy and async SharedPreferences APIs.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app renders navigation', (tester) async {
    await tester.pumpWidget(const SalawatQuranApp());

    // Two pumps only — HomeScreen may use a Timer.periodic that would
    // make pumpAndSettle() time out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Quran'), findsOneWidget);
  });
}
