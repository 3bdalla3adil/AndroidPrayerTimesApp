import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:salawat_quran/models/quran_page.dart';
import 'package:salawat_quran/models/verse.dart';
import 'package:salawat_quran/providers/reader_provider.dart';
import 'package:salawat_quran/repositories/quran_repository.dart';

import 'package:salawat_quran/screens/quran_reader_screen.dart';
import 'package:salawat_quran/services/locale_controller.dart';

class _TestQuranSource implements QuranPageDataSource {
  const _TestQuranSource();

  @override
  Future<QuranPage> loadPage(int page) async => QuranPage(
    pageNumber: page,
    verses: const [
      Verse(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      ),
    ],
  );
}

Future<void> pumpReaderFrames(WidgetTester tester, {int frames = 8}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}


double readerScrollOffset(WidgetTester tester) {
  final listFinder = find.byType(ScrollablePositionedList);
  final scrollableFinder = find.descendant(
    of: listFinder,
    matching: find.byType(Scrollable),
  );
  expect(scrollableFinder, findsOneWidget);
  return tester.state<ScrollableState>(scrollableFinder).position.pixels;
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
      ProviderScope(
        overrides: [
          quranRepositoryProvider.overrideWithValue(
            QuranRepository(const _TestQuranSource(), maximumCachedPages: 604),
          ),
        ],
        child: const MaterialApp(home: QuranReaderScreen(surahNumber: 1)),
      ),
    );
    // Use an in-memory Quran source so this test exercises scrolling, not disk
    // asset decoding. Production asset preloading is covered by repository tests.
    expect(find.byType(ScrollablePositionedList), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  }

  testWidgets('Quran reader continuously scrolls across page boundaries',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mountReader(tester);
    final listFinder = find.byType(ScrollablePositionedList);
    final initialOffset = readerScrollOffset(tester);

    await tester.drag(listFinder, const Offset(0, -650));
    await pumpReaderFrames(tester, frames: 12);

    expect(
      readerScrollOffset(tester),
      greaterThan(initialOffset),
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
    final initialOffset = readerScrollOffset(tester);

    await tester.fling(listFinder, const Offset(0, -120), 12000);
    await pumpReaderFrames(tester, frames: 20);

    expect(
      readerScrollOffset(tester),
      greaterThan(initialOffset),
      reason: 'A fling should continue naturally instead of snapping to one page.',
    );
  });
}
