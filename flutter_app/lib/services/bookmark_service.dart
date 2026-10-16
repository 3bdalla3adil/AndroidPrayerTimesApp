import '../models/bookmark.dart';
import 'storage_service.dart';

/// Typed bookmark operations over the existing persistent StorageService.
///
/// Storage remains backward-compatible with the established "surah:ayah"
/// preference format while the app transitions to typed bookmark objects.
final class BookmarkService {
  BookmarkService(this._storage);

  final StorageService _storage;

  Future<List<Bookmark>> loadAll({
    required int Function(int surah, int ayah) pageForAyah,
  }) async {
    final tuples = await _storage.loadBookmarks();
    final seen = <String>{};
    final result = <Bookmark>[];
    for (final (surah, ayah) in tuples) {
      final bookmark = Bookmark(
        surah: surah,
        ayah: ayah,
        page: pageForAyah(surah, ayah),
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      if (seen.add(bookmark.id)) result.add(bookmark);
    }
    return List.unmodifiable(result);
  }

  Future<bool> toggle({
    required int surah,
    required int ayah,
    required int page,
  }) async {
    if (surah < 1 || surah > 114 || ayah < 1 || page < 1 || page > 604) {
      throw ArgumentError('Invalid bookmark coordinates');
    }

    final current = await _storage.loadBookmarks();
    final exists = current.any((item) => item.$1 == surah && item.$2 == ayah);
    final updated = current
        .where((item) => item.$1 != surah || item.$2 != ayah)
        .toList(growable: true);

    if (!exists) updated.add((surah, ayah));
    await _storage.saveBookmarks(updated);
    return !exists;
  }
}
