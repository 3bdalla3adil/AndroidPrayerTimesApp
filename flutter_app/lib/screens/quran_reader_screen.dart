import 'dart:convert';

import 'package:flutter/cupertino.dart';
import '../core/adaptive_page_scaffold.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../services/storage_service.dart';
import '../services/locale_controller.dart';

const kQuranFont = 'KFGQPC HAFS Uthmanic Script';

/// Madinah-style 604-page Mushaf reader.
///
/// The page data is bundled in the application, so pages 1-604 work offline.
/// The visual treatment intentionally follows the traditional printed Mushaf:
/// warm paper, green ornamental framing, Arabic-first typography, surah header,
/// basmala, ayah markers and a fixed page footer.
class QuranReaderScreen extends StatefulWidget {
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
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  static const totalQuranPages = 604;
  static const totalReaderPages = totalQuranPages;

  final _controller = ScrollController();
  final _listViewportKey = GlobalKey();
  final _pageKeys = <int, GlobalKey>{};
  final _storage = StorageService();
  final _cache = <int, Map<String, dynamic>>{};

  int _readerPage = 1;
  double _fontSize = 25;
  double _lineHeight = 1.75;
  bool _showTranslation = false;
  bool _showToolbar = true;
  bool _darkPage = false;
  bool _pageTrackingScheduled = false;
  int? _userScrollStartPage;
  double? _userScrollStartOffset;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
  }

  GlobalKey _keyForPage(int page) =>
      _pageKeys.putIfAbsent(page, GlobalKey.new);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPage() async {
    try {
      final raw =
          await rootBundle.loadString('assets/quran/page-index.json');
      final index = jsonDecode(raw) as Map<String, dynamic>;
      final starts =
          (index['surahStartPages'] as Map?)?.cast<String, dynamic>() ?? {};
      final saved = await _storage.loadQuranFontSize();
      final savedLineHeight = await _storage.loadQuranLineHeight();
      final savedTranslation = await _storage.loadQuranShowTranslation();
      final savedDarkPage = await _storage.loadQuranDarkPage();
      var requestedQuranPage = widget.startingPage ??
          (starts[widget.surahNumber.toString()] as num?)?.toInt() ??
          1;

      if (widget.startingPage == null && widget.startingAyah > 1) {
        final startPage = requestedQuranPage;
        for (var page = startPage; page <= totalQuranPages; page++) {
          final pageData = await _loadPage(page);
          final verses = ((pageData['verses'] as List?) ?? const [])
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList();
          final found = verses.any((verse) =>
              (verse['surah_number'] as num?)?.toInt() == widget.surahNumber &&
              (verse['ayah_number'] as num?)?.toInt() == widget.startingAyah);
          if (found) {
            requestedQuranPage = page;
            break;
          }
          final passedSurah = verses.any((verse) =>
              ((verse['surah_number'] as num?)?.toInt() ?? -1) > widget.surahNumber);
          if (passedSurah) break;
        }
      }
      final requestedReaderPage =
          requestedQuranPage.clamp(1, totalQuranPages).toInt();

      if (!mounted) return;
      setState(() {
        _readerPage = requestedReaderPage;
        _fontSize = saved.clamp(20, 38).toDouble();
        _lineHeight = savedLineHeight.clamp(1.35, 2.15).toDouble();
        _showTranslation = savedTranslation;
        _darkPage = savedDarkPage;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPage(requestedReaderPage, animated: false);
      });
    } catch (_) {
      // The reader still starts at page 1 if the index cannot be read.
    }
  }

  Future<Map<String, dynamic>> _loadPage(int page, {bool prefetch = true}) async {
    final cached = _cache[page];
    if (cached != null) return cached;

    final path =
        'assets/quran/pages/page-${page.toString().padLeft(3, '0')}.json';
    final decoded = jsonDecode(await rootBundle.loadString(path));
    if (decoded is! Map) {
      throw StateError('Invalid Quran page data.');
    }

    final data = decoded.cast<String, dynamic>();
    _cache[page] = data;

    // Warm only the two adjacent pages. Those requests must not recursively
    // warm their own neighbors, otherwise opening one page loads the whole Quran.
    if (prefetch) {
      for (final adjacent in [page - 1, page + 1]) {
        if (adjacent >= 1 &&
            adjacent <= totalQuranPages &&
            !_cache.containsKey(adjacent)) {
          _loadPage(adjacent, prefetch: false).ignore();
        }
      }
    }

    return data;
  }

  Future<void> _scrollToPage(int page, {bool animated = true}) async {
    if (page < 1 || page > totalReaderPages) return;

    final targetKey = _keyForPage(page);
    for (var attempt = 0; attempt < 20; attempt++) {
      if (!_controller.hasClients) {
        await WidgetsBinding.instance.endOfFrame;
        continue;
      }

      final target = targetKey.currentContext;
      if (target != null) {
        await Scrollable.ensureVisible(
          target,
          duration: animated && attempt == 0
              ? const Duration(milliseconds: 220)
              : Duration.zero,
          curve: Curves.easeOutCubic,
          alignment: 0.0,
        );
        if (mounted && _readerPage != page) {
          setState(() => _readerPage = page);
        }
        return;
      }

      // Estimate the destination from the pages already laid out. ListView
      // builds the next range on each jump, so distant targets need no
      // separate measurement or page-estimation helper.
      final viewport = _listViewportKey.currentContext?.findRenderObject();
      final centerY = viewport is RenderBox && viewport.hasSize
          ? (viewport.localToGlobal(Offset.zero) & viewport.size).center.dy
          : 0.0;
      var nearestPage = _readerPage;
      var nearestDistance = double.infinity;
      final heights = <double>[];

      for (final entry in _pageKeys.entries) {
        final renderObject = entry.value.currentContext?.findRenderObject();
        if (renderObject is! RenderBox || !renderObject.hasSize) continue;
        heights.add(renderObject.size.height);
        final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
        final distance = centerY < rect.top
            ? rect.top - centerY
            : centerY > rect.bottom
                ? centerY - rect.bottom
                : 0.0;
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestPage = entry.key;
        }
      }

      heights.sort();
      final extent = heights.isEmpty
          ? _controller.position.viewportDimension
          : heights[heights.length ~/ 2];
      final delta = page - nearestPage;
      final offset = (_controller.offset +
              (delta == 0
                  ? (page >= nearestPage ? 1 : -1) *
                      _controller.position.viewportDimension
                  : delta * extent))
          .clamp(0.0, _controller.position.maxScrollExtent)
          .toDouble();

      if ((offset - _controller.offset).abs() < 1) break;
      if (animated && attempt == 0) {
        await _controller.animateTo(
          offset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        _controller.jumpTo(offset);
      }
      await WidgetsBinding.instance.endOfFrame;
    }

    final target = targetKey.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        duration: Duration.zero,
        alignment: 0.02,
      );
      if (mounted) setState(() => _readerPage = page);
    }
  }

  Future<void> _bookmarkCurrentPage() async {
    if (_readerPage < 1) return;
    final data = await _loadPage(_readerPage);
    final verses = ((data['verses'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
    if (verses.isEmpty) return;
    final surah = (verses.first['surah_number'] as num?)?.toInt();
    final ayah = (verses.first['ayah_number'] as num?)?.toInt();
    if (surah == null || ayah == null) return;
    final bookmarks = await _storage.loadBookmarks();
    final exists = bookmarks.any((b) => b.$1 == surah && b.$2 == ayah);
    if (exists) {
      bookmarks.removeWhere((b) => b.$1 == surah && b.$2 == ayah);
    } else {
      bookmarks.add((surah, ayah));
    }
    await _storage.saveBookmarks(bookmarks);
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(exists ? 'Bookmark removed' : 'Ayah bookmarked'),
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

  Future<void> _bookmarkAyah(int surah, int ayah) async {
    final bookmarks = await _storage.loadBookmarks();
    final exists = bookmarks.any((b) => b.$1 == surah && b.$2 == ayah);
    if (exists) {
      bookmarks.removeWhere((b) => b.$1 == surah && b.$2 == ayah);
    } else {
      bookmarks.add((surah, ayah));
    }
    await _storage.saveBookmarks(bookmarks);
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(exists ? 'Bookmark removed' : 'Ayah bookmarked'),
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

    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ـ', '')
        .trim();
    final needle = normalize(query);
    final matches = <({int surah, int ayah, int page, String text})>[];
    var totalMatches = 0;
    for (var surah = 1; surah <= quran.totalSurahCount; surah++) {
      for (var ayah = 1; ayah <= quran.getVerseCount(surah); ayah++) {
        final arabic = quran.getVerse(surah, ayah);
        final translation = quran.getVerseTranslation(surah, ayah);
        if (normalize(arabic).contains(needle) ||
            translation.toLowerCase().contains(needle)) {
          totalMatches++;
          if (matches.length < 40) {
            matches.add((
              surah: surah,
              ayah: ayah,
              page: quran.getPageNumber(surah, ayah),
              text: arabic,
            ));
          }
        }
      }
    }

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
                    match.text,
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
            _storage.saveQuranFontSize(value);
          }

          void updateLineHeight(double value) {
            sheetSetState(() {});
            setState(() => _lineHeight = value);
            _storage.saveQuranLineHeight(value);
          }

          void updateTranslation(bool value) {
            sheetSetState(() {});
            setState(() => _showTranslation = value);
            _storage.saveQuranShowTranslation(value);
          }

          void updateDarkPage(bool value) {
            sheetSetState(() {});
            setState(() => _darkPage = value);
            _storage.saveQuranDarkPage(value);
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
                  if (notification.depth != 0) return false;

                  // Capture the page at the start of a real finger drag.
                  // When it ends, settle at only one adjacent page, even
                  // when the release velocity is high.
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _userScrollStartPage = _readerPage;
                    _userScrollStartOffset = notification.metrics.pixels;
                    return false;
                  }

                  // Some scroll activities report their first user
                  // direction through UserScrollNotification rather than a
                  // ScrollStartNotification with dragDetails. Capture that
                  // first directional update as a fallback so the snap still
                  // runs on devices/test environments with different gesture
                  // notification timing.
                  if (notification is UserScrollNotification &&
                      notification.direction != ScrollDirection.idle &&
                      _userScrollStartPage == null) {
                    _userScrollStartPage = _readerPage;
                    _userScrollStartOffset = notification.metrics.pixels;
                    return false;
                  }

                  if (notification is ScrollEndNotification) {
                    final startPage = _userScrollStartPage;
                    final startOffset = _userScrollStartOffset;
                    _userScrollStartPage = null;
                    _userScrollStartOffset = null;

                    if (startPage != null && startOffset != null) {
                      final delta = notification.metrics.pixels - startOffset;
                      final targetPage = delta.abs() < 20
                          ? startPage
                          : (startPage + (delta > 0 ? 1 : -1))
                              .clamp(1, totalReaderPages)
                              .toInt();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        if (_readerPage != targetPage) {
                          setState(() => _readerPage = targetPage);
                        }
                        _scrollToPage(targetPage);
                      });
                      return false;
                    }
                  }

                  if (notification is! ScrollUpdateNotification &&
                      notification is! UserScrollNotification) {
                    return false;
                  }
                  if (_pageTrackingScheduled) return false;

                  _pageTrackingScheduled = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _pageTrackingScheduled = false;
                    if (!mounted) return;

                    final viewport =
                        _listViewportKey.currentContext?.findRenderObject();
                    if (viewport is! RenderBox || !viewport.hasSize) return;
                    final viewportRect =
                        viewport.localToGlobal(Offset.zero) & viewport.size;
                    final centerY = viewportRect.center.dy;
                    var visiblePage = -1;
                    var nearestDistance = double.infinity;

                    for (final entry in _pageKeys.entries) {
                      final renderObject =
                          entry.value.currentContext?.findRenderObject();
                      if (renderObject is! RenderBox || !renderObject.hasSize) {
                        continue;
                      }
                      final rect =
                          renderObject.localToGlobal(Offset.zero) & renderObject.size;
                      final distance = centerY < rect.top
                          ? rect.top - centerY
                          : centerY > rect.bottom
                              ? centerY - rect.bottom
                              : 0.0;
                      if (distance < nearestDistance) {
                        nearestDistance = distance;
                        visiblePage = entry.key;
                      }
                    }

                    if (visiblePage > 0 && visiblePage != _readerPage) {
                      setState(() => _readerPage = visiblePage);
                    }
                  });
                  return false;
                },
                child: ListView.builder(
                  key: _listViewportKey,
                  controller: _controller,
                  physics: const _ControlledReaderScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: totalReaderPages,
                  itemBuilder: (context, index) {
                    final page = index + 1;
                    return KeyedSubtree(
                      key: _keyForPage(page),
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _loadPage(page),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CupertinoActivityIndicator(radius: 14),
                            );
                          }
                          if (snapshot.hasError || snapshot.data == null) {
                            return _ErrorPage(
                              page: page,
                              onRetry: () => setState(() {}),
                            );
                          }
                          return _MushafPage(
                            page: page,
                            data: snapshot.data!,
                            fontSize: _fontSize,
                            lineHeight: _lineHeight,
                            showTranslation: _showTranslation,
                            darkPage: _darkPage,
                            onBookmarkAyah: _bookmarkAyah,
                          );
                        },
                      ),
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
    required this.data,
    required this.fontSize,
    required this.lineHeight,
    required this.showTranslation,
    required this.darkPage,
    required this.onBookmarkAyah,
  });

  final int page;
  final Map<String, dynamic> data;
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

  String _ayahKey(Map<String, dynamic> verse) {
    final surah = (verse['surah_number'] as num?)?.toInt() ?? 0;
    final ayah = (verse['ayah_number'] as num?)?.toInt() ?? 0;
    return '$surah:$ayah';
  }

  bool _isHighlighted(Map<String, dynamic> verse) =>
      _highlightedAyah == _ayahKey(verse);

  void _toggleHighlight(Map<String, dynamic> verse) {
    final key = _ayahKey(verse);
    setState(() {
      _highlightedAyah = _highlightedAyah == key ? null : key;
    });
    // Highlighting is temporary; never persist the last page or ayah.
  }

  List<Map<String, dynamic>> get verses =>
      ((widget.data['verses'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();

  String _verseText(Map<String, dynamic> verse) {
    final words = ((verse['words'] as List?) ?? const [])
        .whereType<Map>()
        .map((word) => (word['text'] ?? '').toString())
        .where((text) => text.isNotEmpty)
        .join(' ');
    return words.isEmpty
        ? (verse['text'] ?? '').toString()
        : words;
  }

  int get _firstSurah =>
      (verses.isEmpty ? 1 : (verses.first['surah_number'] as num?)?.toInt() ?? 1);

  bool get _startsSurah =>
      verses.isNotEmpty &&
      ((verses.first['ayah_number'] as num?)?.toInt() ?? 0) == 1;

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
                        number: (verse['ayah_number'] as num?)?.toInt() ?? 0,
                        color: green,
                        darkPage: widget.darkPage,
                        onTap: () {
                          final surah = (verse['surah_number'] as num?)?.toInt();
                          final ayah = (verse['ayah_number'] as num?)?.toInt();
                          if (surah != null && ayah != null) {
                            widget.onBookmarkAyah(surah, ayah);
                          }
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

  String _translation(Map<String, dynamic> verse) {
    final surah = (verse['surah_number'] as num?)?.toInt();
    final ayah = (verse['ayah_number'] as num?)?.toInt();
    if (surah == null || ayah == null) return '';
    try {
      return quran.getVerseTranslation(surah, ayah);
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
