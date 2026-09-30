import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;

import '../lib/features/quran/data/datasources/quran_package_data_source.dart';
import '../lib/features/quran/data/repositories/quran_repository_impl.dart';
import '../lib/core/result.dart';

void main() {
  test('bundled Quran source exposes all 114 surahs', () async {
    expect(quran.totalSurahCount, 114);
    final source = QuranPackageDataSource();
    final verses = await source.getSurah(1);
    expect(verses.length, 7);
    expect(verses.first.arabicText, contains('بِسۡمِ'));
  });

  test('repository returns a successful ayah result', () async {
    final repository = QuranRepositoryImpl(QuranPackageDataSource());
    final result = await repository.getVerse(1, 1);
    expect(result, isA<Success>());
    expect((result as Success).value.ayahNumber, 1);
  });
}
