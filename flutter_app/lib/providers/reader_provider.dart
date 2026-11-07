import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bookmark.dart';
import '../repositories/quran_repository.dart';
import '../services/search_service.dart';

class ReaderState {
  const ReaderState({
    this.currentPage = 1,
    this.fontSize = 25,
    this.lineHeight = 1.75,
    this.darkMode = false,
    this.translationEnabled = false,
    this.bookmarks = const <Bookmark>[],
  });

  final int currentPage;
  final double fontSize;
  final double lineHeight;
  final bool darkMode;
  final bool translationEnabled;
  final List<Bookmark> bookmarks;

  ReaderState copyWith({
    int? currentPage,
    double? fontSize,
    double? lineHeight,
    bool? darkMode,
    bool? translationEnabled,
    List<Bookmark>? bookmarks,
  }) {
    return ReaderState(
      currentPage: currentPage ?? this.currentPage,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      darkMode: darkMode ?? this.darkMode,
      translationEnabled: translationEnabled ?? this.translationEnabled,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}

final class ReaderController extends Notifier<ReaderState> {
  @override
  ReaderState build() => const ReaderState();

  void setCurrentPage(int page) {
    if (page < 1 || page > 604 || page == state.currentPage) return;
    state = state.copyWith(currentPage: page);
  }

  void setFontSize(double value) {
    state = state.copyWith(fontSize: value.clamp(20, 38).toDouble());
  }

  void setLineHeight(double value) {
    state = state.copyWith(lineHeight: value.clamp(1.35, 2.15).toDouble());
  }

  void setDarkMode(bool value) {
    state = state.copyWith(darkMode: value);
  }

  void setTranslationEnabled(bool value) {
    state = state.copyWith(translationEnabled: value);
  }

  void setBookmarks(List<Bookmark> bookmarks) {
    state = state.copyWith(bookmarks: List.unmodifiable(bookmarks));
  }

  void restore({
    required int page,
    required double fontSize,
    required double lineHeight,
    required bool darkMode,
    required bool translationEnabled,
    List<Bookmark>? bookmarks,
  }) {
    state = ReaderState(
      currentPage: page.clamp(1, 604).toInt(),
      fontSize: fontSize.clamp(20, 38).toDouble(),
      lineHeight: lineHeight.clamp(1.35, 2.15).toDouble(),
      darkMode: darkMode,
      translationEnabled: translationEnabled,
      bookmarks: List.unmodifiable(bookmarks ?? state.bookmarks),
    );
  }
}

final readerProvider =
    NotifierProvider<ReaderController, ReaderState>(ReaderController.new);

final quranRepositoryProvider = Provider<QuranRepository>(
  (ref) => QuranRepository(const AssetQuranPageDataSource(), maximumCachedPages: 604),
);

final quranSearchServiceProvider = Provider<QuranSearchService>(
  (ref) => QuranSearchService(),
);
