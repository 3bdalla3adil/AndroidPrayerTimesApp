import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/screens/quran_reader_screen.dart';
import 'package:salawat_quran/services/locale_controller.dart';

Future<void> pumpReaderFrames(WidgetTester tester, {int frames = 8}) async {
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

  Future<ScrollController> mountReader(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    await tester.pumpWidget(
      const MaterialApp(home: QuranReaderScreen(surahNumber: 1)),
    );
    await pumpReaderFrames(tester);
    final listFinder = find.byType(ListView);
    expect(listFinder, findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    return tester.widget<ListView>(listFinder).controller!;
  }

  testWidgets('Quran reader settles one adjacent page per vertical drag',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await mountReader(tester);
    final listFinder = find.byType(ListView);
    final startOffset = controller.offset;

    await tester.drag(listFinder, const Offset(0, -650));
    await pumpReaderFrames(tester, frames: 12);

    expect(find.textContaining('صفحة 2 من 604'), findsOneWidget);
    expect(controller.offset, greaterThan(startOffset));
  });

  testWidgets('Quran reader fling settles at one adjacent page only',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await mountReader(tester);
    final listFinder = find.byType(ListView);
    final startOffset = controller.offset;

    await tester.fling(listFinder, const Offset(0, -120), 12000);
    await pumpReaderFrames(tester, frames: 20);

    expect(find.textContaining('صفحة 2 من 604'), findsOneWidget);
    expect(controller.offset, greaterThan(startOffset));
  });
}
