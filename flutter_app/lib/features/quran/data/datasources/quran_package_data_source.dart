import 'package:quran/quran.dart' as quran;

import '../../domain/entities/quran_verse.dart';
import 'quran_local_data_source.dart';

final class QuranPackageDataSource implements QuranLocalDataSource {
  @override
  Future<List<QuranVerse>> getSurah(int surahNumber) async {
    final count = quran.getVerseCount(surahNumber);
    return List.generate(count, (index) {
      final ayah = index + 1;
      return QuranVerse(
        surahNumber: surahNumber,
        ayahNumber: ayah,
        arabicText: quran.getVerse(surahNumber, ayah),
        translationEn: quran.getVerseTranslation(surahNumber, ayah),
      );
    });
  }

  @override
  Future<List<QuranVerse>> search(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final matches = <QuranVerse>[];
    for (var surah = 1; surah <= quran.totalSurahCount; surah++) {
      final verses = await getSurah(surah);
      for (final verse in verses) {
        final haystack = verse.arabicText + ' ' + (verse.translationEn ?? '');
        if (haystack.toLowerCase().contains(needle)) matches.add(verse);
      }
    }
    return matches;
  }

  @override
  Future<QuranVerse> getVerse(int surahNumber, int ayahNumber) async {
    if (ayahNumber < 1 || ayahNumber > quran.getVerseCount(surahNumber)) {
      throw RangeError('Invalid ayah number: ' + ayahNumber.toString());
    }
    return QuranVerse(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      arabicText: quran.getVerse(surahNumber, ayahNumber),
      translationEn: quran.getVerseTranslation(surahNumber, ayahNumber),
    );
  }
}
