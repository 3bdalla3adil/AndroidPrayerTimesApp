import 'verse.dart';

class SearchResult {
  const SearchResult({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.arabicText,
    this.translation,
  });

  final int surah;
  final int ayah;
  final int page;
  final String arabicText;
  final String? translation;

  String get id => '$surah:$ayah';

  factory SearchResult.fromVerse({
    required Verse verse,
    required int page,
    String? translation,
  }) {
    return SearchResult(
      surah: verse.surahNumber,
      ayah: verse.ayahNumber,
      page: page,
      arabicText: verse.displayText,
      translation: translation,
    );
  }
}
