import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/app.dart';
import 'package:salawat_quran/screens/quran_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock the legacy API (SharedPreferences.getInstance)
    SharedPreferences.setMockInitialValues({});

    // Mock the async API (SharedPreferencesAsync) — this is what
    // StorageService actually uses, and it needs its own mock.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('app renders navigation', (tester) async {
    await tester.pumpWidget(const SalawatQuranApp());

    // Two pumps only — HomeScreen has a Timer.periodic that would
    // make pumpAndSettle() time out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('السلام عليكم'), findsOneWidget);
    expect(find.text('استكشف التطبيق'), findsOneWidget);

    // The current home-led layout opens features as Cupertino routes.
    await tester.tap(find.text('القرآن الكريم').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(QuranScreen), findsOneWidget);
  });
}
