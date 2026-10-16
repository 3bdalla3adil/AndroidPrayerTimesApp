import 'package:quran/quran.dart' as quran;

import '../models/search_result.dart';
import '../models/verse.dart';

/// Builds a normalized Quran search corpus once and reuses it for later queries.
final class QuranSearchService {
  final List<_IndexedVerse> _verses = [];
  final Map<String, Set<int>> _postings = {};
  bool _built = false;

  bool get isBuilt => _built;

  static final RegExp _diacritics =
      RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]');
  static final RegExp _tokenizer = RegExp(r'\s+');

  static String normalize(String value) => value
      .toLowerCase()
      .replaceAll(_diacritics, '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ـ', '')
      .trim();

  Future<void> build() async {
    if (_built) return;

    // The quran package is bundled locally; no network requests are performed.
    for (var surah = 1; surah <= quran.totalSurahCount; surah++) {
      final count = quran.getVerseCount(surah);
      for (var ayah = 1; ayah <= count; ayah++) {
        final arabic = quran.getVerse(surah, ayah);
        final translation = quran.getVerseTranslation(surah, ayah);
        final item = _IndexedVerse(
          verse: Verse(
            surahNumber: surah,
            ayahNumber: ayah,
            text: arabic,
          ),
          page: quran.getPageNumber(surah, ayah),
          arabicNormalized: normalize(arabic),
          translationNormalized: normalize(translation),
          translation: translation,
        );
        final index = _verses.length;
        _verses.add(item);

        for (final token in <String>{
          ...item.arabicNormalized.split(_tokenizer),
          ...item.translationNormalized.split(_tokenizer),
        }) {
          if (token.isEmpty) continue;
          _postings.putIfAbsent(token, () => <int>{}).add(index);
        }
      }
    }

    _built = true;
  }

  List<SearchResult> search(String rawQuery, {int limit = 40}) {
    if (!_built) {
      throw StateError('Call build() before searching the Quran');
    }
    if (limit <= 0) return const [];

    final needle = normalize(rawQuery);
    if (needle.isEmpty) return const [];

    // Preserve the existing substring-search semantics. Token postings narrow
    // common word searches; short/substring queries use the normalized corpus.
    final tokens = needle.split(_tokenizer).where((token) => token.isNotEmpty);
    Set<int>? candidates;
    for (final token in tokens) {
      final matches = _postings[token] ?? const <int>{};
      candidates = candidates == null
          ? Set<int>.from(matches)
          : candidates.intersection(matches);
      if (candidates.isEmpty) return const [];
    }

    final indexes = candidates?.toList() ??
        List<int>.generate(_verses.length, (index) => index);
    final results = <SearchResult>[];

    for (final index in indexes) {
      final item = _verses[index];
      if (!item.arabicNormalized.contains(needle) &&
          !item.translationNormalized.contains(needle)) {
        continue;
      }
      results.add(SearchResult.fromVerse(
        verse: item.verse,
        page: item.page,
        translation: item.translation,
      ));
      if (results.length >= limit) break;
    }

    // Posting sets are not ordered, so sort by canonical Quran order.
    results.sort((a, b) {
      final surahOrder = a.surah.compareTo(b.surah);
      return surahOrder != 0 ? surahOrder : a.ayah.compareTo(b.ayah);
    });
    return List.unmodifiable(results);
  }
}

class _IndexedVerse {
  const _IndexedVerse({
    required this.verse,
    required this.page,
    required this.arabicNormalized,
    required this.translationNormalized,
    required this.translation,
  });

  final Verse verse;
  final int page;
  final String arabicNormalized;
  final String translationNormalized;
  final String translation;
}
