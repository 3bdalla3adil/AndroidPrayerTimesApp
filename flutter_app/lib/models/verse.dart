class Verse {
  const Verse({
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
    this.words = const <String>[],
  });

  final int surahNumber;
  final int ayahNumber;
  final String text;
  final List<String> words;

  String get id => '$surahNumber:$ayahNumber';

  String get displayText {
    final wordText = words.where((word) => word.isNotEmpty).join(' ');
    return wordText.isEmpty ? text : wordText;
  }

  factory Verse.fromJson(Map<String, dynamic> json) {
    int requiredInt(String key) {
      final value = json[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      throw FormatException('Invalid Quran verse field: $key');
    }

    final rawText = json['text'];
    final rawWords = json['words'];
    final words = rawWords is List
        ? rawWords.whereType<Map>().map((word) {
            final value = word['text'];
            return value is String ? value : '';
          }).where((word) => word.isNotEmpty).toList(growable: false)
        : const <String>[];

    if (rawText is! String && words.isEmpty) {
      throw const FormatException('Quran verse is missing text');
    }

    final surah = requiredInt('surah_number');
    final ayah = requiredInt('ayah_number');
    if (surah < 1 || surah > 114 || ayah < 1) {
      throw const FormatException('Quran verse coordinates are invalid');
    }

    return Verse(
      surahNumber: surah,
      ayahNumber: ayah,
      text: rawText is String ? rawText : '',
      words: List.unmodifiable(words),
    );
  }
}
