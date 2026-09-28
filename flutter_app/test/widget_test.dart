import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_quran/app.dart';

void main() {
  // Required so plugin channels are available before any widget builds.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Initialize the async SharedPreferences platform used by the app.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app renders navigation', (tester) async {
    await tester.pumpWidget(const SalawatQuranApp());

    // Let the first frame settle, but DON'T pumpAndSettle —
    // the app has a Timer.periodic(1s) that never stops.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Quran'), findsOneWidget);
  });
}
