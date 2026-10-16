import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/screens/quran_reader_screen.dart';
import 'package:salawat_quran/services/locale_controller.dart';

Future<void> pumpReaderFrames(WidgetTester tester, {int frames = 8}) async {
  // Page data is loaded asynchronously and the app may have repeating timers.
  // Use bounded pumping so tests do not wait forever for unrelated callbacks.
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    LocaleController.locale.value = const Locale('ar');
  });

  testWidgets('Quran reader scrolls vertically without nested scrollers',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: QuranReaderScreen(surahNumber: 1)),
    );
    await pumpReaderFrames(tester);

    final listFinder = find.byType(ListView);
    expect(listFinder, findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);

    final list = tester.widget<ListView>(listFinder);
    final controller = list.controller;
    expect(controller, isNotNull);

    final startOffset = controller!.offset;
    await tester.drag(listFinder, const Offset(0, -500));
    await pumpReaderFrames(tester, frames: 4);

    expect(controller.offset, greaterThan(startOffset));
  });

  testWidgets('Quran reader limits vertical fling momentum',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: QuranReaderScreen(surahNumber: 1)),
    );
    await pumpReaderFrames(tester);

    final listFinder = find.byType(ListView);
    expect(listFinder, findsOneWidget);
    final controller = tester.widget<ListView>(listFinder).controller!;
    final startOffset = controller.offset;

    await tester.fling(listFinder, const Offset(0, -120), 12000);
    await pumpReaderFrames(tester, frames: 12);

    // The custom physics caps velocity; a short gesture must not coast through
    // a large portion of the Mushaf after release.
    expect(controller.offset - startOffset, lessThan(1500));
    expect(controller.offset, greaterThan(startOffset));
  });
}
