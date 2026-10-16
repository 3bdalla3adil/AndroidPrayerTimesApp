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
    this.maximumCachedPages = 20,
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

  void prefetchAround(int page) {
    for (final neighbor in [page - 1, page + 1]) {
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
