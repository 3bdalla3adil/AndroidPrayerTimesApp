import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:salawat_quran/services/storage_service.dart';

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
    // The reader intentionally has no blocking preparation overlay. Wait for
    // page 1's data-backed widget instead, leaving the UI interactive while
    // bundled data and preferences finish loading in the background.
    final firstPage = find.byKey(const ValueKey('quran-page-loaded-1'));
    for (var frame = 0; frame < 200 && firstPage.evaluate().isEmpty; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (frame == 20) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
      }
    }
    expect(
      firstPage,
      findsOneWidget,
      reason: 'The first Mushaf page should load without a blocking spinner.',
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);

    // Allow the initial indexed jump to settle before user-driven scroll checks.
    await pumpReaderFrames(tester, frames: 4);
    expect(find.byType(ScrollablePositionedList), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  }

  test('auto-scroll speed preference persists and is clamped', () async {
    final storage = StorageService();
    await storage.saveQuranAutoScrollSecondsPerPage(42);
    expect(await storage.loadQuranAutoScrollSecondsPerPage(), 42);
    await storage.saveQuranAutoScrollSecondsPerPage(2);
    expect(await storage.loadQuranAutoScrollSecondsPerPage(), 10);
    await storage.saveQuranAutoScrollSecondsPerPage(90);
    expect(await storage.loadQuranAutoScrollSecondsPerPage(), 60);
  });

  test('ayah toolbar preference persists with enabled default', () async {
    final storage = StorageService();
    expect(await storage.loadQuranAyahToolbarEnabled(), isTrue);

    await storage.saveQuranAyahToolbarEnabled(false);
    expect(await StorageService().loadQuranAyahToolbarEnabled(), isFalse);

    await storage.saveQuranAyahToolbarEnabled(true);
    expect(await StorageService().loadQuranAyahToolbarEnabled(), isTrue);
  });

  test('last opened Quran page persists and is restored by storage', () async {
    final storage = StorageService();
    await storage.saveLastQuranPage(287);

    // A new service instance represents a fresh app/reader session.
    expect(await StorageService().loadLastQuranPage(), 287);
  });

  test('last opened Quran page is clamped to the 604-page Mushaf', () async {
    final storage = StorageService();
    await storage.saveLastQuranPage(999);
    expect(await storage.loadLastQuranPage(), 604);
    await storage.saveLastQuranPage(0);
    expect(await storage.loadLastQuranPage(), 1);
  });

  testWidgets('reader chrome hides during manual scrolling and returns when idle',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mountReader(tester);

    final listFinder = find.byType(ScrollablePositionedList);
    expect(find.byKey(const ValueKey('quran-reader-app-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('quran-reader-header-navigator')), findsOneWidget);
    expect(find.byKey(const ValueKey('quran-reader-bottom-toolbar')), findsOneWidget);

    await tester.drag(listFinder, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('quran-reader-app-bar')), findsNothing);
    expect(find.byKey(const ValueKey('quran-reader-header-navigator')), findsNothing);
    expect(find.byKey(const ValueKey('quran-reader-bottom-toolbar')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(find.byKey(const ValueKey('quran-reader-app-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('quran-reader-header-navigator')), findsOneWidget);
    expect(find.byKey(const ValueKey('quran-reader-bottom-toolbar')), findsOneWidget);
  });

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
