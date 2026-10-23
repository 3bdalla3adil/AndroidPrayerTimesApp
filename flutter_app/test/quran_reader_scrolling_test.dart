import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/screens/quran_reader_screen.dart';
import 'package:salawat_quran/services/locale_controller.dart';
import 'package:salawat_quran/providers/reader_provider.dart';

Future<void> pumpReaderFrames(WidgetTester tester, {int frames = 8}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}


int lastVisibleMushafPageIndex(WidgetTester tester) {
  final list = tester.widget<ScrollablePositionedList>(
    find.byType(ScrollablePositionedList),
  );
  final positions = list.itemPositionsListener.itemPositions.value;
  if (positions.isEmpty) return -1;
  return positions
      .map((position) => position.index)
      .reduce((left, right) => left > right ? left : right);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    LocaleController.locale.value = const Locale('ar');
  });

  Future<void> mountReader(
    WidgetTester tester, {
    Size size = const Size(900, 1400),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: QuranReaderScreen(surahNumber: 1)),
      ),
    );
    await pumpReaderFrames(tester);
    expect(find.byType(ScrollablePositionedList), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  }

  testWidgets('Quran reader continuously scrolls across page boundaries',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mountReader(tester);
    final listFinder = find.byType(ScrollablePositionedList);
    final firstVisibleMaxIndex = lastVisibleMushafPageIndex(tester);

    await tester.drag(listFinder, const Offset(0, -650));
    await pumpReaderFrames(tester, frames: 12);

    expect(
      lastVisibleMushafPageIndex(tester),
      greaterThan(firstVisibleMaxIndex),
      reason: 'A continuous drag should reveal later Mushaf pages without snapping.',
    );
  });


  testWidgets('overflow-aware page scrolls content taller than its viewport',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 700));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: OverflowAwarePageScrollView(
              page: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  30,
                  (index) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'آية قرآنية طويلة لاختبار التمرير ${index + 1}',
                      style: const TextStyle(fontSize: 38, height: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await pumpReaderFrames(tester, frames: 8);

    final pageScroll = find.byKey(const ValueKey('quran-page-scroll-1'));
    expect(pageScroll, findsOneWidget);
    final scrollable = find.descendant(
      of: pageScroll,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);

    final scrollState = tester.state<ScrollableState>(scrollable);
    expect(scrollState.position.maxScrollExtent, greaterThan(0));

    await tester.drag(pageScroll, const Offset(0, -240));
    await pumpReaderFrames(tester, frames: 4);
    expect(scrollState.position.pixels, greaterThan(0));
  });

  testWidgets('Quran reader fling can continue across multiple pages',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mountReader(tester);
    final listFinder = find.byType(ScrollablePositionedList);
    final firstVisibleMaxIndex = lastVisibleMushafPageIndex(tester);

    await tester.fling(listFinder, const Offset(0, -120), 12000);
    await pumpReaderFrames(tester, frames: 20);

    expect(
      lastVisibleMushafPageIndex(tester),
      greaterThan(firstVisibleMaxIndex),
      reason: 'A fling should continue naturally instead of snapping to one page.',
    );
  });
}
