class Bookmark {
  const Bookmark({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.createdAt,
  });

  final int surah;
  final int ayah;
  final int page;
  final DateTime createdAt;

  String get id => '$surah:$ayah';

  Map<String, Object?> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'page': page,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    final surah = (json['surah'] as num?)?.toInt();
    final ayah = (json['ayah'] as num?)?.toInt();
    final page = (json['page'] as num?)?.toInt();
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '');

    if (surah == null ||
        surah < 1 ||
        surah > 114 ||
        ayah == null ||
        ayah < 1 ||
        page == null ||
        page < 1 ||
        page > 604 ||
        createdAt == null) {
      throw const FormatException('Invalid Quran bookmark');
    }

    return Bookmark(
      surah: surah,
      ayah: ayah,
      page: page,
      createdAt: createdAt,
    );
  }
}
