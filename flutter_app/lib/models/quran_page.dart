import 'verse.dart';

class QuranPage {
  const QuranPage({
    required this.pageNumber,
    required this.verses,
  });

  final int pageNumber;
  final List<Verse> verses;

  factory QuranPage.fromJson(int pageNumber, Map<String, dynamic> json) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(pageNumber, 1, 604, 'pageNumber');
    }

    final rawVerses = json['verses'];
    if (rawVerses is! List) {
      throw FormatException('Page $pageNumber has no verse list');
    }

    final verses = rawVerses.map((raw) {
      if (raw is! Map) {
        throw FormatException('Page $pageNumber contains an invalid verse');
      }
      return Verse.fromJson(Map<String, dynamic>.from(raw));
    }).toList(growable: false);

    if (verses.isEmpty) {
      throw FormatException('Page $pageNumber contains no verses');
    }

    return QuranPage(
      pageNumber: pageNumber,
      verses: List.unmodifiable(verses),
    );
  }
}
