class QuranWord {
  const QuranWord({
    required this.position,
    required this.arabic,
    this.translation,
    this.transliteration,
  });

  final int position;
  final String arabic;
  final String? translation;
  final String? transliteration;
}

class QuranVerse {
  const QuranVerse({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabicText,
    this.translationEn,
    this.transliteration,
    this.words = const [],
    this.tafsirEn,
    this.tafsirAr,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabicText;
  final String? translationEn;
  final String? transliteration;
  final List<QuranWord> words;
  final String? tafsirEn;
  final String? tafsirAr;

  String get key => '$surahNumber:$ayahNumber';
}
