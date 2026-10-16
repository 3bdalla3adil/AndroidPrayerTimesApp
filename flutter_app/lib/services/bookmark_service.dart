import 'dart:convert';

import 'package:quran/quran.dart' as quran;

import '../models/bookmark.dart';
import 'storage_service.dart';

/// Typed bookmark operations with a one-time migration from legacy surah:ayah
/// preferences. The legacy list is kept synchronized for older app screens.
final class BookmarkService {
  BookmarkService(this._storage);

  final StorageService _storage;

  Future<List<Bookmark>> loadAll() async {
    final stored = await _storage.loadBookmarkRecords();
    if (stored.isNotEmpty) {
      final decoded = <Bookmark>[];
      for (final record in stored) {
        try {
          final json = jsonDecode(record);
          if (json is Map) {
            decoded.add(Bookmark.fromJson(Map<String, dynamic>.from(json)));
          }
        } on FormatException {
          // Ignore corrupt entries rather than failing the whole bookmark list.
        } on TypeError {
          // Ignore records with an incompatible schema.
        }
      }
      final unique = <String, Bookmark>{};
      for (final item in decoded) {
        unique[item.id] = item;
      }
      return List.unmodifiable(unique.values);
    }

    final legacy = await _storage.loadBookmarks();
    final now = DateTime.now().toUtc();
    final migrated = <Bookmark>[];
    for (final (surah, ayah) in legacy) {
      if (ayah > quran.getVerseCount(surah)) continue;
      migrated.add(Bookmark(
        surah: surah,
        ayah: ayah,
        page: quran.getPageNumber(surah, ayah),
        createdAt: now,
      ));
    }

    if (migrated.isNotEmpty) {
      await _save(migrated);
    }
    return List.unmodifiable(migrated);
  }

  Future<bool> toggle({
    required int surah,
    required int ayah,
    required int page,
  }) async {
    if (surah < 1 ||
        surah > 114 ||
        ayah < 1 ||
        ayah > quran.getVerseCount(surah) ||
        page < 1 ||
        page > 604) {
      throw ArgumentError('Invalid bookmark coordinates');
    }

    final current = await loadAll();
    final exists = current.any((item) => item.id == '$surah:$ayah');
    final updated = current
        .where((item) => item.id != '$surah:$ayah')
        .toList(growable: true);

    if (!exists) {
      updated.add(Bookmark(
        surah: surah,
        ayah: ayah,
        page: page,
        createdAt: DateTime.now().toUtc(),
      ));
    }
    await _save(updated);
    return !exists;
  }

  Future<void> _save(List<Bookmark> bookmarks) async {
    final unique = <String, Bookmark>{};
    for (final bookmark in bookmarks) {
      unique[bookmark.id] = bookmark;
    }
    final values = unique.values.toList(growable: false);
    await _storage.saveBookmarkRecords(
      values.map((bookmark) => jsonEncode(bookmark.toJson())).toList(),
    );
    await _storage.saveBookmarks(
      values.map((bookmark) => (bookmark.surah, bookmark.ayah)).toList(),
    );
  }
}
