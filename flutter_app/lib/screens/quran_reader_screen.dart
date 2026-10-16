import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/adaptive_page_scaffold.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../services/storage_service.dart';
import '../repositories/quran_repository.dart';
import '../models/quran_page.dart';
import '../models/verse.dart';
import '../services/search_service.dart';
import '../services/bookmark_service.dart';
import '../services/settings_service.dart';
import '../providers/reader_provider.dart';
import '../services/locale_controller.dart';

const kQuranFont = 'KFGQPC HAFS Uthmanic Script';

/// Madinah-style 604-page Mushaf reader.
///
/// The page data is bundled in the application, so pages 1-604 work offline.
/// The visual treatment intentionally follows the traditional printed Mushaf:
/// warm paper, green ornamental framing, Arabic-first typography, surah header,
/// basmala, ayah markers and a fixed page footer.
class QuranReaderScreen extends ConsumerStatefulWidget {
  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.startingAyah = 1,
    this.startingPage,
  });

  final int surahNumber;
  final int startingAyah;
  final int? startingPage;

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  static const totalQuranPages = 604;
  static const totalReaderPages = totalQuranPages;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  bool _isProgrammaticNavigation = false;
  int _navigationGeneration = 0;
  final _storage = StorageService();
  late final _bookmarkService = BookmarkService(_storage);
  late final _settingsService = SettingsService(_storage);
  late final QuranRepository _repository;
  final LinkedHashMap<int, Future<QuranPage>> _pageFutures = LinkedHashMap();
  late final QuranSearchService _searchService;

  int get _readerPage => ref.read(readerProvider).currentPage;
  set _readerPage(int value) => ref.read(readerProvider.notifier).setCurrentPage(value);

  double get _fontSize => ref.read(readerProvider).fontSize;
  set _fontSize(double value) => ref.read(readerProvider.notifier).setFontSize(value);

  double get _lineHeight => ref.read(readerProvider).lineHeight;
  set _lineHeight(double value) => ref.read(readerProvider.notifier).setLineHeight(value);

  bool get _showTranslation => ref.read(readerProvider).translationEnabled;
  set _showTranslation(bool value) =>
      ref.read(readerProvider.notifier).setTranslationEnabled(value);

  bool _showToolbar = true;

  bool get _darkPage => ref.read(readerProvider).darkMode;
  set _darkPage(bool value) => ref.read(readerProvider.notifier).setDarkMode(value);
  bool _pageTrackingScheduled = false;
  int? _userScrollStartPage;
  double? _userScrollStartOffset;
  int _userScrollDirection = 0;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(quranRepositoryProvider);
    _searchService = ref.read(quranSearchServiceProvider);
    _itemPositionsListener.itemPositions.addListener(
      _handleItemPositionsChanged,
    );
    _loadInitialPage();
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _handleItemPositionsChanged,
    );
    super.dispose();
  }

  Future<void> _loadInitialPage() async {
    try {
      final raw =
          await rootBundle.loadString('assets/quran/page-index.json');
      final index = jsonDecode(raw) as Map<String, dynamic>;
      final starts =
          (index['surahStartPages'] as Map?)?.cast<String, dynamic>() ?? {};
      final settings = await _settingsService.load();
      final bookmarks = await _bookmarkService.loadAll();
      var requestedQuranPage = widget.startingPage ??
          (starts[widget.surahNumber.toString()] as num?)?.toInt() ??
          1;

      if (widget.startingPage == null && widget.startingAyah > 1) {
        final startPage = requestedQuranPage;
        for (var page = startPage; page <= totalQuranPages; page++) {
          final pageData = await _loadPage(page, prefetch: false);
          final found = pageData.verses.any((verse) =>
              verse.surahNumber == widget.surahNumber &&
              verse.ayahNumber == widget.startingAyah);
          if (found) {
            requestedQuranPage = page;
            break;
          }
          final passedSurah = pageData.verses.any(
            (verse) => verse.surahNumber > widget.surahNumber,
          );
          if (passedSurah) break;
        }
      }
      final requestedReaderPage =
          requestedQuranPage.clamp(1, totalQuranPages).toInt();

      if (!mounted) return;
      ref.read(readerProvider.notifier).restore(
        page: requestedReaderPage,
        fontSize: settings.fontSize,
        lineHeight: settings.lineHeight,
        translationEnabled: settings.showTranslation,
        darkMode: settings.darkPage,
        bookmarks: bookmarks,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPage(requestedReaderPage, animated: false);
      });
    } catch (_) {
      // The reader still starts at page 1 if the index cannot be read.
    }
  }

  Future<QuranPage> _loadPage(int page, {bool prefetch = true}) async {
    final data = await _repository.loadPage(page);
    if (prefetch) _repository.prefetchAround(page);
    return data;
  }

  Future<QuranPage> _pageFuture(int page) {
    final existing = _pageFutures.remove(page);
    if (existing != null) {
      _pageFutures[page] = existing;
      return existing;
    }

    final future = _loadPage(page);
    _pageFutures[page] = future;
    while (_pageFutures.length > 24) {
      _pageFutures.remove(_pageFutures.keys.first);
    }
    return future;
  }

  Future<void> _scrollToPage(int page, {bool animated = true}) async {
    if (page < 1 || page > totalReaderPages) return;

    final generation = ++_navigationGeneration;
    _isProgrammaticNavigation = true;
    _userScrollStartPage = null;
    _userScrollStartOffset = null;
    _userScrollDirection = 0;

    try {
      if (!_itemScrollController.isAttached) {
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!_itemScrollController.isAttached || !mounted) return;

      if (animated) {
        await _itemScrollController.scrollTo(
          index: page - 1,
          alignment: 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        _itemScrollController.jumpTo(
          index: page - 1,
          alignment: 0,
        );
      }

      if (mounted && generation == _navigationGeneration) {
        setState(() => _readerPage = page);
        _repository.prefetchAround(page);
      }
    } finally {
      if (generation == _navigationGeneration) {
        _isProgrammaticNavigation = false;
      }
    }
  }

  void _handleItemPositionsChanged() {
    if (!mounted ||
        _isProgrammaticNavigation ||
        _userScrollStartPage != null) {
      return;
    }

    final positions = _itemPositionsListener.itemPositions.value
        .where((position) =>
            position.index >= 0 && position.index < totalReaderPages)
        .toList(growable: false);
    if (positions.isEmpty) return;

    final nearest = positions.reduce((left, right) {
      final leftCenter = (left.itemLeadingEdge + left.itemTrailingEdge) / 2;
      final rightCenter = (right.itemLeadingEdge + right.itemTrailingEdge) / 2;
      return (leftCenter - 0.5).abs() <= (rightCenter - 0.5).abs()
          ? left
          : right;
    });
    final page = nearest.index + 1;
    if (page != _readerPage) {
      setState(() => _readerPage = page);
    }
  }

  Future<void> _bookmarkCurrentPage() async {
    if (_readerPage < 1) return;
    final data = await _loadPage(_readerPage);
    if (data.verses.isEmpty) return;
    final verse = data.verses.first;
    await _toggleBookmark(
      surah: verse.surahNumber,
      ayah: verse.ayahNumber,
      page: _readerPage,
    );
  }

  Future<void> _bookmarkAyah(int surah, int ayah) async {
    await _toggleBookmark(
      surah: surah,
      ayah: ayah,
      page: quran.getPageNumber(surah, ayah),
    );
  }

  Future<void> _toggleBookmark({
    required int surah,
    required int ayah,
    required int page,
  }) async {
    final added = await _bookmarkService.toggle(
      surah: surah,
      ayah: ayah,
      page: page,
    );
    ref.read(readerProvider.notifier).setBookmarks(
      await _bookmarkService.loadAll(),
    );
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(added ? 'Ayah bookmarked' : 'Bookmark removed'),
        content: Text('${quran.getSurahName(surah)} • Ayah $ayah'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  Future<int?> _askNumber({
    required String title,
    required String placeholder,
    required int min,
    required int max,
  }) async {
    final input = TextEditingController();
    final value = await showCupertinoDialog<int>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: CupertinoTextField(
            controller: input,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            placeholder: placeholder,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleController.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final number = int.tryParse(input.text.trim());
              if (number != null && number >= min && number <= max) {
                Navigator.pop(dialogContext, number);
              }
            },
            child: Text(LocaleController.isArabic ? 'انتقال' : 'Go'),
          ),
        ],
      ),
    );
    input.dispose();
    return value;
  }

  Future<void> _openNavigator() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: Text(LocaleController.isArabic ? 'التنقّل في القرآن' : 'Browse Quran'),
        message: Text(LocaleController.isArabic
            ? 'انتقل حسب السورة أو الآية أو الصفحة أو الجزء'
            : 'Jump to a surah, ayah, page, or juz'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(popupContext);
              _askNumber(
                title: LocaleController.isArabic ? 'رقم السورة' : 'Surah number',
                placeholder: '1 - 114',
                min: 1,
                max: 114,
              ).then((surah) {
                if (surah != null) {
                  _scrollToPage(quran.getPageNumber(surah, 1));
                }
              });
            },
            child: Text(LocaleController.isArabic ? 'حسب السورة' : 'Go to surah'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(popupContext);
              _navigateByAyah();
            },
            child: Text(LocaleController.isArabic ? 'حسب السورة والآية' : 'Go to surah and ayah'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(popupContext);
              _askNumber(
                title: LocaleController.isArabic ? 'رقم الصفحة' : 'Page number',
                placeholder: '1 - 604',
                min: 1,
                max: totalQuranPages,
              ).then((page) {
                if (page != null) _scrollToPage(page);
              });
            },
            child: Text(LocaleController.isArabic ? 'حسب الصفحة' : 'Go to page'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(popupContext);
              _askNumber(
                title: LocaleController.isArabic ? 'رقم الجزء' : 'Juz number',
                placeholder: '1 - 30',
                min: 1,
                max: 30,
              ).then((juz) {
                if (juz == null) return;
                final verses = quran.getSurahAndVersesFromJuz(juz);
                if (verses.isEmpty) return;
                final firstSurah = verses.keys.toList()..sort();
                final surah = firstSurah.first;
                final ayah = verses[surah]?.first ?? 1;
                _scrollToPage(quran.getPageNumber(surah, ayah));
              });
            },
            child: Text(LocaleController.isArabic ? 'حسب الجزء' : 'Go to juz'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(popupContext);
              _searchQuran();
            },
            child: Text(LocaleController.isArabic ? 'البحث في القرآن' : 'Search Quran'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: Text(LocaleController.isArabic ? 'إلغاء' : 'Cancel'),
        ),
      ),
    );
  }

  Future<void> _navigateByAyah() async {
    final surah = await _askNumber(
      title: LocaleController.isArabic ? 'رقم السورة' : 'Surah number',
      placeholder: '1 - 114',
      min: 1,
      max: 114,
    );
    if (surah == null || !mounted) return;
    final ayah = await _askNumber(
      title: LocaleController.isArabic
          ? 'رقم الآية في سورة ${quran.getSurahNameArabic(surah)}'
          : 'Ayah in ${quran.getSurahName(surah)}',
      placeholder: '1 - ${quran.getVerseCount(surah)}',
      min: 1,
      max: quran.getVerseCount(surah),
    );
    if (ayah != null) _scrollToPage(quran.getPageNumber(surah, ayah));
  }

  Future<void> _searchQuran() async {
    final input = TextEditingController();
    final query = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(LocaleController.isArabic ? 'البحث في القرآن' : 'Search Quran'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: CupertinoTextField(
            controller: input,
            autofocus: true,
            placeholder: LocaleController.isArabic
                ? 'اكتب كلمة أو عبارة'
                : 'Enter a word or phrase',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleController.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final value = input.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: Text(LocaleController.isArabic ? 'بحث' : 'Search'),
          ),
        ],
      ),
    );
    input.dispose();
    if (query == null || query.trim().isEmpty || !mounted) return;

    if (!_searchService.isBuilt) {
      await _searchService.build();
    }
    final searchResponse = _searchService.search(query, limit: 40);
    final matches = searchResponse.results;
    final totalMatches = searchResponse.totalMatches;

    if (!mounted) return;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: Text(LocaleController.isArabic
            ? 'نتائج البحث: $totalMatches'
            : 'Search results: $totalMatches'),
        message: totalMatches == 0
            ? Text(LocaleController.isArabic ? 'لا توجد نتائج' : 'No results found')
            : (totalMatches > matches.length
                ? Text(LocaleController.isArabic
                    ? 'يتم عرض أول ${matches.length} نتيجة'
                    : 'Showing the first ${matches.length} results')
                : null),
        actions: [
          for (final match in matches)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(popupContext);
                _scrollToPage(match.page);
              },
              child: Column(
                children: [
                  Text(
                    '${quran.getSurahNameArabic(match.surah)} • ${match.surah}:${match.ayah}',
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    match.arabicText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: Text(LocaleController.isArabic ? 'إغلاق' : 'Close'),
        ),
      ),
    );
  }

  void _jumpToPage() {
    final input = TextEditingController(text: '$_readerPage');
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(LocaleController.isArabic ? 'الانتقال إلى صفحة' : 'Go to page'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: CupertinoTextField(
            controller: input,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            placeholder: '1 - 604',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(LocaleController.isArabic ? 'إلغاء' : 'Cancel'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(LocaleController.isArabic ? 'انتقال' : 'Go'),
            onPressed: () {
              final value = int.tryParse(input.text.trim());
              Navigator.pop(dialogContext);
              if (value != null) _scrollToPage(value.clamp(1, totalQuranPages).toInt());
            },
          ),
        ],
      ),
    );
  }

  void _openReaderSettings() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => StatefulBuilder(
        builder: (popupContext, sheetSetState) {
          void updateFontSize(double value) {
            sheetSetState(() {});
            setState(() => _fontSize = value);
            _settingsService.saveFontSize(value);
          }

          void updateLineHeight(double value) {
            sheetSetState(() {});
            setState(() => _lineHeight = value);
            _settingsService.saveLineHeight(value);
          }

          void updateTranslation(bool value) {
            sheetSetState(() {});
            setState(() => _showTranslation = value);
            _settingsService.saveTranslation(value);
          }

          void updateDarkPage(bool value) {
            sheetSetState(() {});
            setState(() => _darkPage = value);
            _settingsService.saveDarkPage(value);
          }

          return CupertinoActionSheet(
            title: Text(LocaleController.isArabic ? 'إعدادات المصحف' : 'Mushaf settings'),
            message: Column(
              children: [
                const SizedBox(height: 8),
                Text(LocaleController.isArabic ? 'حجم الخط: ${_fontSize.round()}' : 'Font size: ${_fontSize.round()}'),
                CupertinoSlider(
                  min: 20,
                  max: 38,
                  value: _fontSize,
                  onChanged: updateFontSize,
                ),
                Text(LocaleController.isArabic ? 'تباعد السطور: ${_lineHeight.toStringAsFixed(2)}' : 'Line spacing: ${_lineHeight.toStringAsFixed(2)}'),
                CupertinoSlider(
                  min: 1.35,
                  max: 2.15,
                  value: _lineHeight,
                  onChanged: updateLineHeight,
                ),
                CupertinoListTile(
                  title: Text(LocaleController.isArabic ? 'الترجمة الإنجليزية' : 'English translation'),
                  trailing: CupertinoSwitch(
                    value: _showTranslation,
                    onChanged: updateTranslation,
                  ),
                ),
                CupertinoListTile(
                  title: Text(LocaleController.isArabic ? 'صفحة داكنة' : 'Dark page'),
                  trailing: CupertinoSwitch(
                    value: _darkPage,
                    onChanged: updateDarkPage,
                  ),
                ),
              ],
            ),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(popupContext),
              child: Text(LocaleController.isArabic ? 'إغلاق' : 'Close'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Select individual fields so the screen rebuilds only for reader-state
    // changes that affect its visible content.
    ref.watch(readerProvider.select((state) => state.currentPage));
    ref.watch(readerProvider.select((state) => state.fontSize));
    ref.watch(readerProvider.select((state) => state.lineHeight));
    ref.watch(readerProvider.select((state) => state.darkMode));
    ref.watch(readerProvider.select((state) => state.translationEnabled));

    final background = CupertinoColors.systemGroupedBackground
        .resolveFrom(context);

    return AdaptivePageScaffold(
      backgroundColor: background,
      navigationBar: CupertinoNavigationBar(
        middle: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              LocaleController.isArabic ? 'القرآن الكريم' : 'The Holy Quran',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              LocaleController.isArabic ? 'صفحة $_readerPage من $totalQuranPages' : 'Page $_readerPage of $totalQuranPages',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _showToolbar = !_showToolbar),
          child: Icon(
            _showToolbar
                ? CupertinoIcons.eye_slash
                : CupertinoIcons.eye,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_showToolbar) _ReaderToolbar(
              onNavigate: _openNavigator,
              onSearch: _searchQuran,
              onSettings: _openReaderSettings,
              onBookmark: _bookmarkCurrentPage,
              page: _readerPage,
              totalPages: totalReaderPages,
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.depth != 0 || _isProgrammaticNavigation) {
                    return false;
                  }

                  // Capture the page at the start of a real finger drag.
                  // When it ends, settle at only one adjacent page, even
                  // when the release velocity is high.
                  if (notification is ScrollStartNotification) {
                    _userScrollStartPage ??= _readerPage;
                    _userScrollStartOffset ??= notification.metrics.pixels;
                    _userScrollDirection = 0;
                  }

                  if (notification is UserScrollNotification &&
                      notification.direction != ScrollDirection.idle) {
                    _userScrollDirection =
                        notification.direction == ScrollDirection.reverse
                            ? 1
                            : -1;
                    _userScrollStartPage ??= _readerPage;
                    _userScrollStartOffset ??= notification.metrics.pixels;
                  }

                  if (notification is ScrollEndNotification) {
                    final startPage = _userScrollStartPage;
                    final startOffset = _userScrollStartOffset;
                    final direction = _userScrollDirection;
                    _userScrollStartPage = null;
                    _userScrollStartOffset = null;
                    _userScrollDirection = 0;

                    if (startPage != null && startOffset != null) {
                      final delta = notification.metrics.pixels - startOffset;
                      final resolvedDirection = direction != 0
                          ? direction
                          : delta.abs() < 20
                              ? 0
                              : (delta > 0 ? 1 : -1);
                      final targetPage = (startPage + resolvedDirection)
                          .clamp(1, totalReaderPages)
                          .toInt();

                      // Suppress item-position updates between gesture end and
                      // the deterministic snap to the adjacent page.
                      _isProgrammaticNavigation = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _scrollToPage(targetPage, animated: false);
                      });
                      return false;
                    }
                  }

                  return false;
                },
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  scrollDirection: Axis.vertical,
                  physics: const _ControlledReaderScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: totalReaderPages,
                  itemBuilder: (context, index) {
                    final page = index + 1;
                    return FutureBuilder<QuranPage>(
                        future: _pageFuture(page),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CupertinoActivityIndicator(radius: 14),
                            );
                          }
                          if (snapshot.hasError || snapshot.data == null) {
                            return _ErrorPage(
                              page: page,
                              onRetry: () {
                                _pageFutures.remove(page);
                                setState(() {});
                              },
                            );
                          }
                          return _MushafPage(
                            page: page,
                            pageData: snapshot.data!,
                            fontSize: _fontSize,
                            lineHeight: _lineHeight,
                            showTranslation: _showTranslation,
                            darkPage: _darkPage,
                            onBookmarkAyah: _bookmarkAyah,
                          );
                        },
                    );
                  },
                ),
              ),
            ),
            _PageControls(
              page: _readerPage,
              totalPages: totalReaderPages,
              onPrevious: () => _scrollToPage(_readerPage - 1),
              onNext: () => _scrollToPage(_readerPage + 1),
              onJump: _jumpToPage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderToolbar extends StatelessWidget {
  const _ReaderToolbar({
    required this.onNavigate,
    required this.onSearch,
    required this.onSettings,
    required this.onBookmark,
    required this.page,
    required this.totalPages,
  });

  final VoidCallback onNavigate;
  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onBookmark;
  final int page;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: Row(
        children: [
          _ReaderButton(
            icon: CupertinoIcons.list_bullet,
            label: LocaleController.isArabic ? 'تنقّل' : 'Browse',
            onPressed: onNavigate,
          ),
          _ReaderButton(
            icon: CupertinoIcons.search,
            label: LocaleController.isArabic ? 'بحث' : 'Search',
            onPressed: onSearch,
          ),
          _ReaderButton(
            icon: CupertinoIcons.slider_horizontal_3,
            label: LocaleController.isArabic ? 'المظهر' : 'Appearance',
            onPressed: onSettings,
          ),
          _ReaderButton(
            icon: CupertinoIcons.bookmark,
            label: LocaleController.isArabic ? 'حفظ' : 'Bookmark',
            onPressed: onBookmark,
          ),
          const Spacer(),
          Text(
            '$page / $totalPages',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderButton extends StatelessWidget {
  const _ReaderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      minimumSize: const Size(0, 0),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}

class _MushafPage extends StatefulWidget {
  const _MushafPage({
    required this.page,
    required this.pageData,
    required this.fontSize,
    required this.lineHeight,
    required this.showTranslation,
    required this.darkPage,
    required this.onBookmarkAyah,
  });

  final int page;
  final QuranPage pageData;
  final double fontSize;
  final double lineHeight;
  final bool showTranslation;
  final bool darkPage;
  final Future<void> Function(int surah, int ayah) onBookmarkAyah;
  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  final Map<String, TapGestureRecognizer> _ayahRecognizers = {};
  String? _highlightedAyah;

  @override
  void dispose() {
    for (final recognizer in _ayahRecognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _recognizerFor(String key, VoidCallback onTap) {
    final existing = _ayahRecognizers[key];
    if (existing != null) return existing;
    final recognizer = TapGestureRecognizer()..onTap = onTap;
    _ayahRecognizers[key] = recognizer;
    return recognizer;
  }

  String _ayahKey(Verse verse) => verse.id;

  bool _isHighlighted(Verse verse) => _highlightedAyah == _ayahKey(verse);

  void _toggleHighlight(Verse verse) {
    final key = _ayahKey(verse);
    setState(() {
      _highlightedAyah = _highlightedAyah == key ? null : key;
    });
    // Highlighting is temporary; never persist the last page or ayah.
  }

  List<Verse> get verses => widget.pageData.verses;

  String _verseText(Verse verse) => verse.displayText;

  int get _firstSurah => verses.isEmpty ? 1 : verses.first.surahNumber;

  bool get _startsSurah => verses.isNotEmpty && verses.first.ayahNumber == 1;

  bool get _hasBasmala => _startsSurah && _firstSurah != 9;

  @override
  Widget build(BuildContext context) {
    final pageBg = widget.darkPage
        ? const Color(0xFF17211C)
        : const Color(0xFFFFFFFF);
    final ink = widget.darkPage
        ? const Color(0xFFECE8D9)
        : const Color(0xFF202124);
    final green = widget.darkPage
        ? const Color(0xFF9CC8A8)
        : const Color(0xFF176B52);
    final divider = widget.darkPage
        ? const Color(0xFF50675A)
        : const Color(0xFFE0E0E0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
      decoration: BoxDecoration(
        color: pageBg,
        border: Border(bottom: BorderSide(color: divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_startsSurah) ...[
            _SurahHeader(
              arabic: quran.getSurahNameArabic(_firstSurah),
              english: quran.getSurahName(_firstSurah),
              color: green,
              border: divider,
            ),
            if (_hasBasmala) ...[
              const SizedBox(height: 12),
              Text(
                'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kQuranFont,
                  fontFamilyFallback: const ['Noto Naskh Arabic', 'Arial', 'serif'],
                  fontSize: widget.fontSize - 2,
                  height: 1.6,
                  color: ink,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(
                children: [
                  for (final verse in verses) ...[
                    TextSpan(
                      text: '${_verseText(verse)} ',
                      style: TextStyle(
                        fontFamily: kQuranFont,
                        fontFamilyFallback: const ['Noto Naskh Arabic', 'Arial', 'serif'],
                        fontSize: widget.fontSize,
                        height: widget.lineHeight,
                        color: _isHighlighted(verse)
                            ? (widget.darkPage
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF176B52))
                            : ink,
                        backgroundColor: _isHighlighted(verse)
                            ? const Color(0x33176B52)
                            : null,
                        fontWeight: FontWeight.w400,
                      ),
                      recognizer: _recognizerFor(
                        _ayahKey(verse),
                        () => _toggleHighlight(verse),
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _AyahMarker(
                        number: verse.ayahNumber,
                        color: green,
                        darkPage: widget.darkPage,
                        onTap: () {
                          widget.onBookmarkAyah(
                            verse.surahNumber,
                            verse.ayahNumber,
                          );
                        },
                      ),
                    ),
                    if (widget.showTranslation)
                      TextSpan(
                        text: '\n${_translation(verse)}\n',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 13,
                          height: 1.45,
                          color: widget.darkPage
                              ? const Color(0xFFB9C5BD)
                              : const Color(0xFF657269),
                        ),
                      ),
                  ],
                ],
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              '— ${widget.page} —',
              style: TextStyle(
                fontSize: 11,
                color: green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _translation(Verse verse) {
    try {
      return quran.getVerseTranslation(
        verse.surahNumber,
        verse.ayahNumber,
      );
    } catch (_) {
      return '';
    }
  }
}
class _AyahMarker extends StatelessWidget {
  const _AyahMarker({
    required this.number,
    required this.color,
    required this.darkPage,
    required this.onTap,
  });

  final int number;
  final Color color;
  final bool darkPage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          '۝${_arabicNumber(number)}',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: kQuranFont,
            fontSize: 12,
            color: darkPage ? const Color(0xFFE6E0C8) : color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


class _SurahHeader extends StatelessWidget {
  const _SurahHeader({
    required this.arabic,
    required this.english,
    required this.color,
    required this.border,
  });

  final String arabic;
  final String english;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kQuranFont,
              fontFamilyFallback: const ['Noto Naskh Arabic', 'Arial', 'serif'],
              fontSize: 23,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            english,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: .8)),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: border.withValues(alpha: .6)),
        ],
      ),
    );
  }
}

String _arabicNumber(int value) {
  const western = '0123456789';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  return value
      .toString()
      .split('')
      .map((digit) => arabic[western.indexOf(digit)])
      .join();
}

class _PageControls extends StatelessWidget {
  const _PageControls({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onJump,
  });

  final int page;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: page > 1 ? onPrevious : null,
            child: const Icon(CupertinoIcons.chevron_left),
          ),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              onPressed: onJump,
              child: Text(
                LocaleController.isArabic ? 'صفحة $page / $totalPages' : 'Page $page / $totalPages',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: page < totalPages ? onNext : null,
            child: const Icon(CupertinoIcons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.page, required this.onRetry});

  final int page;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoButton.filled(
        onPressed: onRetry,
        child: Text(LocaleController.isArabic ? 'إعادة تحميل الصفحة $page' : 'Retry loading page $page'),
      ),
    );
  }
}


/// Keeps the reader's scrolling natural while limiting excessive fling
/// momentum. Direct finger dragging and explicit page navigation remain enabled.
class _ControlledReaderScrollPhysics extends ClampingScrollPhysics {
  const _ControlledReaderScrollPhysics({super.parent});

  static const double _maximumFlingVelocity = 1600;

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final boundedVelocity = velocity
        .clamp(-_maximumFlingVelocity, _maximumFlingVelocity)
        .toDouble();
    return super.createBallisticSimulation(position, boundedVelocity);
  }

  @override
  _ControlledReaderScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _ControlledReaderScrollPhysics(parent: buildParent(ancestor));
}
