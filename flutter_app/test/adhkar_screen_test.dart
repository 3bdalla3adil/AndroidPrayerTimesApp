import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/screens/adhkar_screen.dart';
import 'package:salawat_quran/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('daily adhkar counters increment, decrement, and persist', () async {
    final storage = StorageService();
    await storage.saveAdhkarProgress({'0': 2});

    expect(await storage.loadAdhkarProgress(), {'0': 2});

    await storage.saveAdhkarProgress({'0': 1, '1': 4});
    expect(await storage.loadAdhkarProgress(), {'0': 1, '1': 4});
  });

  test('daily progress is isolated by local calendar date', () async {
    final storage = StorageService();
    final dayOne = DateTime(2026, 11, 7);
    final dayTwo = DateTime(2026, 11, 8);

    await storage.saveAdhkarProgress({'0': 3}, date: dayOne);

    expect(await storage.loadAdhkarProgress(date: dayOne), {'0': 3});
    expect(await storage.loadAdhkarProgress(date: dayTwo), isEmpty);
  });

  test('malformed adhkar progress entries are ignored', () async {
    final storage = StorageService();
    await storage.prefs.setStringList(
      'daily_adhkar_progress_2026-11-07',
      const ['0:2', 'bad-entry', '1:nope', ':4', '2:-1'],
    );

    expect(
      await storage.loadAdhkarProgress(date: DateTime(2026, 11, 7)),
      {'0': 2},
    );
  });

  testWidgets('adhkar screen shows counters and saves a repetition', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdhkarScreen()));
    await tester.pumpAndSettle();

    expect(find.text('TODAY’S PROGRESS'), findsOneWidget);
    expect(find.text('0 / 73 repetitions'), findsOneWidget);
    expect(find.text('Astaghfirullah'), findsOneWidget);

    await tester.tap(find.widgetWithText(CupertinoButton, 'Count').first);
    await tester.pumpAndSettle();

    expect(find.text('1 / 73 repetitions'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(await StorageService().loadAdhkarProgress(), {'0': 1});
  });
}
