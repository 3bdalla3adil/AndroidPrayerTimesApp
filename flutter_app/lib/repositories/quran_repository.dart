import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quran_page.dart';

abstract interface class QuranPageDataSource {
  Future<QuranPage> loadPage(int page);
}

final class AssetQuranPageDataSource implements QuranPageDataSource {
  const AssetQuranPageDataSource({AssetBundle? bundle}) : _bundle = bundle;

  final AssetBundle? _bundle;

  @override
  Future<QuranPage> loadPage(int page) async {
    if (page < 1 || page > 604) {
      throw RangeError.range(page, 1, 604, 'page');
    }

    final path = 'assets/quran/pages/page-${page.toString().padLeft(3, '0')}.json';
    final raw = await (_bundle ?? rootBundle).loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('Invalid JSON for Quran page $page');
    }

    return QuranPage.fromJson(page, Map<String, dynamic>.from(decoded));
  }
}

/// Offline page repository with bounded LRU caching and request deduplication.
final class QuranRepository {
  QuranRepository(
    this._source, {
    this.maximumCachedPages = 604,
  }) : assert(maximumCachedPages > 0);

  final QuranPageDataSource _source;
  final int maximumCachedPages;
  final LinkedHashMap<int, QuranPage> _cache = LinkedHashMap<int, QuranPage>();
  final Map<int, Future<QuranPage>> _inFlight = {};

  Future<QuranPage> loadPage(int page) async {
    if (page < 1 || page > 604) {
      throw RangeError.range(page, 1, 604, 'page');
    }

    final cached = _cache.remove(page);
    if (cached != null) {
      _cache[page] = cached;
      return cached;
    }

    final pending = _inFlight[page];
    if (pending != null) return pending;

    final request = _source.loadPage(page);
    _inFlight[page] = request;
    try {
      final result = await request;
      if (result.pageNumber != page) {
        throw FormatException(
          'Requested Quran page $page but data source returned ${result.pageNumber}',
        );
      }

      _cache.remove(page);
      _cache[page] = result;
      while (_cache.length > maximumCachedPages) {
        _cache.remove(_cache.keys.first);
      }
      return result;
    } finally {
      _inFlight.remove(page);
    }
  }

  /// Loads all bundled Mushaf pages before the reader becomes interactive.
  ///
  /// Work is bounded in small batches to avoid issuing hundreds of simultaneous
  /// asset reads. The decoded cache is capped at the 604-page Mushaf size, so
  /// a normal reading session never evicts a page and flashes a loading state.
  Future<void> preloadAllPages({
    int batchSize = 16,
    int prioritizePage = 1,
    void Function(int loaded, int total)? onProgress,
  }) async {
    if (batchSize < 1) throw ArgumentError.value(batchSize, 'batchSize');
    const totalPages = 604;
    final priority = prioritizePage.clamp(1, totalPages);
    // Warm the visible page's neighborhood first, then expand outward. This
    // avoids blank placeholders when a reader opens deep into the Mushaf.
    final orderedPages = List<int>.generate(totalPages, (index) => index + 1)
      ..sort((left, right) {
        final distance = (left - priority).abs().compareTo((right - priority).abs());
        return distance != 0 ? distance : left.compareTo(right);
      });
    var loaded = 0;
    for (var start = 0; start < orderedPages.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, orderedPages.length);
      await Future.wait([
        for (final page in orderedPages.sublist(start, end)) loadPage(page),
      ]);
      loaded = end;
      onProgress?.call(loaded, totalPages);
    }
  }

  /// Returns an already decoded page synchronously so scrolling never shows
  /// a loading placeholder for content that is in memory.
  QuranPage? cachedPage(int page) => _cache[page];

  /// Warms a small window around the visible page. Requests are deduplicated by
  /// [loadPage], and the bounded LRU cache prevents unbounded memory growth.
  void prefetchAround(int page, {int radius = 3}) {
    for (var neighbor = page - radius; neighbor <= page + radius; neighbor++) {
      if (neighbor < 1 || neighbor > 604) continue;
      if (_cache.containsKey(neighbor) || _inFlight.containsKey(neighbor)) {
        continue;
      }
      loadPage(neighbor).then<void>((_) {}, onError: (Object _, StackTrace __) {});
    }
  }

  void clearCache() => _cache.clear();

  int get cachedPageCount => _cache.length;
}
