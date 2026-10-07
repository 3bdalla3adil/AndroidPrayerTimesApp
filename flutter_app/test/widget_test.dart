import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/app.dart';

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

    expect(find.text('Home'), findsOneWidget);

    // CupertinoTabBar displays the selected tab's label. Verify that
    // navigation to Quran works rather than expecting both labels at once.
    await tester.tap(find.byIcon(CupertinoIcons.book));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Quran'), findsOneWidget);
  });
}
