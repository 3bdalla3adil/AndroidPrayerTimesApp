import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_quran/models/quran_page.dart';
import 'package:salawat_quran/models/verse.dart';
import 'package:salawat_quran/repositories/quran_repository.dart';

class _FakeSource implements QuranPageDataSource {
  final Map<int, int> calls = {};
  final Map<int, Completer<QuranPage>> pending = {};

  @override
  Future<QuranPage> loadPage(int page) {
    calls.update(page, (value) => value + 1, ifAbsent: () => 1);
    final completer = pending.putIfAbsent(page, Completer<QuranPage>.new);
    if (!completer.isCompleted) {
      completer.complete(QuranPage(
        pageNumber: page,
        verses: [
          Verse(surahNumber: 1, ayahNumber: page, text: 'verse $page'),
        ],
      ));
    }
    return completer.future;
  }
}

void main() {
  group('QuranRepository', () {
    test('deduplicates concurrent requests for the same page', () async {
      final source = _FakeSource();
      final repository = QuranRepository(source, maximumCachedPages: 2);

      final first = repository.loadPage(1);
      final second = repository.loadPage(1);
      final results = await Future.wait([first, second]);

      expect(source.calls[1], 1);
      expect(identical(results[0], results[1]), isTrue);
    });

    test('evicts least recently used pages at the configured limit', () async {
      final source = _FakeSource();
      final repository = QuranRepository(source, maximumCachedPages: 2);

      await repository.loadPage(1);
      await repository.loadPage(2);
      await repository.loadPage(1); // Page 1 becomes most recently used.
      await repository.loadPage(3); // Page 2 should be evicted.

      expect(repository.cachedPageCount, 2);
      await repository.loadPage(1);
      expect(source.calls[1], 1);
      await repository.loadPage(2);
      expect(source.calls[2], 2);
    });

    test('rejects page numbers outside the Mushaf range', () async {
      final repository = QuranRepository(_FakeSource());
      await expectLater(repository.loadPage(0), throwsRangeError);
      await expectLater(repository.loadPage(605), throwsRangeError);
    });
  });

  test('QuranPage parses typed verse data', () {
    final page = QuranPage.fromJson(1, {
      'verses': [
        {
          'surah_number': 1,
          'ayah_number': 1,
          'text': 'بِسْمِ اللَّهِ',
          'words': [
            {'text': 'بِسْمِ'},
            {'text': 'اللَّهِ'},
          ],
        },
      ],
    });

    expect(page.pageNumber, 1);
    expect(page.verses.single.id, '1:1');
    expect(page.verses.single.displayText, 'بِسْمِ اللَّهِ');
  });
}
