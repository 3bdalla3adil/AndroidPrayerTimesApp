import 'dart:collection';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/adaptive_page_scaffold.dart';
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

/// Keeps post-release scrolling predictable regardless of swipe strength.
/// Finger-driven dragging remains natural; every qualifying fling uses the
/// same velocity so a quick swipe cannot send the reader far ahead.
class FixedSpeedScrollPhysics extends ClampingScrollPhysics {
  const FixedSpeedScrollPhysics({super.parent});

  static const double flingSpeed = 900;

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position.outOfRange ||
        velocity.abs() < toleranceFor(position).velocity) {
      return super.createBallisticSimulation(position, velocity);
    }
    return super.createBallisticSimulation(
      position,
      velocity.sign * flingSpeed,
    );
  }

  @override
  FixedSpeedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FixedSpeedScrollPhysics(parent: buildParent(ancestor));
  }
}

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
  bool _isInitializingReader = true;
  int _navigationGeneration = 0;
  final _storage = StorageService();
  late final _bookmarkService = BookmarkService(_storage);
  late final _settingsService = SettingsService(_storage);
  late final QuranRepository _repository;
  final LinkedHashMap<int, Future<QuranPage>> _pageFutures = LinkedHashMap();
  late final QuranSearchService _searchService;

  int _lastKnownReaderPage = 1;
  int get _readerPage => ref.read(readerProvider).currentPage;
  int get _currentPageSurah {
    final data = _repository.cachedPage(_readerPage);
    return data?.verses.firstOrNull?.surahNumber ?? widget.surahNumber;
  }
  int get _currentPageJuz {
    final verse = _repository.cachedPage(_readerPage)?.verses.firstOrNull;
    return verse == null
        ? quran.getJuzNumber(widget.surahNumber, widget.startingAyah)
        : quran.getJuzNumber(verse.surahNumber, verse.ayahNumber);
  }
  set _readerPage(int value) {
    _lastKnownReaderPage = value;
    ref.read(readerProvider.notifier).setCurrentPage(value);
  }

  double get _fontSize => ref.read(readerProvider).fontSize;
  set _fontSize(double value) => ref.read(readerProvider.notifier).setFontSize(value);

  double get _lineHeight => ref.read(readerProvider).lineHeight;
  set _lineHeight(double value) => ref.read(readerProvider.notifier).setLineHeight(value);

  bool get _showTranslation => ref.read(readerProvider).translationEnabled;
  set _showTranslation(bool value) =>
      ref.read(readerProvider.notifier).setTranslationEnabled(value);

  bool _bottomBarVisible = true;
  bool _readerChromeVisible = true;
  Timer? _chromeVisibilityTimer;
  bool _autoScrollEnabled = false;
  int _autoScrollGeneration = 0;
  double _autoScrollSecondsPerPage = 30;
  bool _ayahToolbarEnabled = true;
  OverlayEntry? _ayahActionOverlay;
  bool _tajweedMode = false;
  String? _selectedAyahKey;
  Set<String> _memorizedAyahs = <String>{};
  Set<String> _reviewAyahs = <String>{};
  bool _memorizationMode = false;
  Verse? _memorizationVerse;
  bool _memorizationBusy = false;
  final Map<int, Offset> _activePointers = <int, Offset>{};
  double? _initialPinchDistance;
  double _pinchStartFontSize = 25;
  Timer? _fontSaveDebounce;
  Timer? _pageSaveDebounce;
  final AudioPlayer _recitationPlayer = AudioPlayer();
  StreamSubscription<void>? _recitationCompleteSubscription;
  StreamSubscription<PlayerState>? _recitationStateSubscription;
  bool _isRecitationPlaying = false;
  bool _isRecitationLoading = false;
  String _selectedReciter = 'Alafasy_128kbps';
  List<Verse> _recitationQueue = const <Verse>[];
  int _recitationIndex = 0;
  int _recitationGeneration = 0;
  static const _reciters = <String, String>{
    'Alafasy_128kbps': 'Mishary Alafasy',
    'Abdul_Basit_Murattal_192kbps': 'Abdul Basit',
    'Husary_128kbps': 'Mahmoud Khalil Al-Husary',
  };

  bool get _darkPage => ref.read(readerProvider).darkMode;
  set _darkPage(bool value) => ref.read(readerProvider.notifier).setDarkMode(value);

  @override
  void initState() {
    super.initState();
    _repository = ref.read(quranRepositoryProvider);
    _searchService = ref.read(quranSearchServiceProvider);
    _itemPositionsListener.itemPositions.addListener(
      _handleItemPositionsChanged,
    );
    _recitationStateSubscription = _recitationPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isRecitationPlaying = state == PlayerState.playing);
    });
    _recitationCompleteSubscription = _recitationPlayer.onPlayerComplete.listen((_) {
      _playNextRecitationVerse();
    });
    _loadInitialPage();
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _handleItemPositionsChanged,
    );
    _recitationGeneration++;
    _recitationCompleteSubscription?.cancel();
    _recitationStateSubscription?.cancel();
    _recitationPlayer.dispose();
    _fontSaveDebounce?.cancel();
    _pageSaveDebounce?.cancel();
    _chromeVisibilityTimer?.cancel();
    // Persist synchronously from the current state when the reader is closed;
    // the debounced write handles normal scrolling without excessive I/O.
    unawaited(_storage.saveLastQuranPage(_lastKnownReaderPage));
    _ayahActionOverlay?.remove();
    _ayahActionOverlay = null;
    super.dispose();
  }

  Future<void> _toggleRecitation() async {
    if (_isRecitationLoading) return;
    if (_isRecitationPlaying) {
      await _recitationPlayer.pause();
      return;
    }
    if (_recitationQueue.isNotEmpty && _recitationIndex < _recitationQueue.length) {
      await _recitationPlayer.resume();
      return;
    }
    final generation = ++_recitationGeneration;
    setState(() => _isRecitationLoading = true);
    try {
      final data = await _loadPage(_readerPage, prefetch: false);
      if (!mounted || generation != _recitationGeneration) return;
      _recitationQueue = data.verses;
      _recitationIndex = 0;
      if (_recitationQueue.isEmpty) return;
      await _playRecitationVerse(generation);
    } catch (_) {
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(LocaleController.isArabic ? 'تعذّر تشغيل التلاوة' : 'Unable to play recitation'),
            content: Text(LocaleController.isArabic
                ? 'تحقّق من اتصال الإنترنت ثم حاول مرة أخرى.'
                : 'Check your internet connection and try again.'),
            actions: [CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(LocaleController.isArabic ? 'حسنًا' : 'OK'),
            )],
          ),
        );
      }
    } finally {
      if (mounted && generation == _recitationGeneration) setState(() => _isRecitationLoading = false);
    }
  }

  String _recitationUrl(Verse verse) {
    final surah = verse.surahNumber.toString().padLeft(3, '0');
    final ayah = verse.ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$_selectedReciter/$surah$ayah.mp3';
  }

  Future<void> _playRecitationVerse(int generation) async {
    if (!mounted || generation != _recitationGeneration || _recitationIndex >= _recitationQueue.length) return;
    await _recitationPlayer.play(UrlSource(_recitationUrl(_recitationQueue[_recitationIndex])));
  }

  Future<void> _playNextRecitationVerse() async {
    if (!mounted || _recitationQueue.isEmpty) return;
    final generation = _recitationGeneration;
    if (_recitationIndex + 1 >= _recitationQueue.length) {
      setState(() {
        _isRecitationPlaying = false;
        _recitationQueue = const <Verse>[];
        _recitationIndex = 0;
      });
      return;
    }
    _recitationIndex++;
    try {
      await _playRecitationVerse(generation);
    } catch (_) {
      if (mounted) setState(() => _isRecitationPlaying = false);
    }
  }

  Future<void> _chooseReciter() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: Text(LocaleController.isArabic ? 'اختر القارئ' : 'Choose reciter'),
        actions: [
          for (final entry in _reciters.entries)
            CupertinoActionSheetAction(
              isDefaultAction: entry.key == _selectedReciter,
              onPressed: () async {
                Navigator.pop(popupContext);
                if (_selectedReciter == entry.key) return;
                _recitationGeneration++;
                await _recitationPlayer.stop();
                if (!mounted) return;
                setState(() {
                  _selectedReciter = entry.key;
                  _recitationQueue = const <Verse>[];
                  _recitationIndex = 0;
                  _isRecitationPlaying = false;
                });
              },
              child: Text(entry.value),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: Text(LocaleController.isArabic ? 'إلغاء' : 'Cancel'),
        ),
      ),
    );
  }

  // Raw pointer events avoid competing with the scroll view's one-finger drag.
  // Pinch zoom only activates while two pointers are down; normal vertical
  // scrolling stays in the scrollable's gesture arena.
  void _handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.position;
    if (_activePointers.length == 2) {
      final points = _activePointers.values.toList(growable: false);
      _initialPinchDistance = (points[0] - points[1]).distance;
      _pinchStartFontSize = _fontSize;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.position;
    if (_activePointers.length < 2) return;
    final points = _activePointers.values.take(2).toList(growable: false);
    final initialDistance = _initialPinchDistance;
    if (initialDistance == null || initialDistance <= 0) return;
    final distance = (points[0] - points[1]).distance;
    final size = (_pinchStartFontSize * distance / initialDistance).clamp(20.0, 38.0);
    if ((size - _fontSize).abs() < 0.25) return;
    setState(() => _fontSize = size);
    _fontSaveDebounce?.cancel();
    _fontSaveDebounce = Timer(const Duration(milliseconds: 300), () {
      _settingsService.saveFontSize(size);
    });
  }

  void _handlePointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) _initialPinchDistance = null;
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
      final memorizedAyahs = await _storage.loadMemorizedAyahs();
      final reviewAyahs = await _storage.loadMemorizationReviewAyahs();
      final shouldRestoreLastPage = widget.startingPage == null &&
          widget.surahNumber == 1 && widget.startingAyah == 1;
      final lastOpenedPage = shouldRestoreLastPage
          ? await _storage.loadLastQuranPage()
          : null;
      var requestedQuranPage = widget.startingPage ??
          lastOpenedPage ??
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

      // Load the requested page before showing the reader. Preloading all 604
      // pages on the critical path makes startup unnecessarily slow (and can
      // leave the reader blocked on slower devices). Warm the full offline cache
      // in the background while the visible page and its neighbors render.
      await _loadPage(requestedReaderPage, prefetch: false);
      if (!mounted) return;
      ref.read(readerProvider.notifier).restore(
        page: requestedReaderPage,
        fontSize: settings.fontSize,
        lineHeight: settings.lineHeight,
        translationEnabled: settings.showTranslation,
        darkMode: settings.darkPage,
        bookmarks: bookmarks,
      );
      _memorizedAyahs = memorizedAyahs;
      _reviewAyahs = reviewAyahs;
      _autoScrollSecondsPerPage = settings.autoScrollSecondsPerPage;
      _ayahToolbarEnabled = settings.ayahToolbarEnabled;
      _lastKnownReaderPage = requestedReaderPage;
      // Prime both sides of the opening page before the full background warmup.
      _repository.prefetchAround(requestedReaderPage, radius: 8);
      unawaited(_repository.preloadAllPages(
        batchSize: 16,
        prioritizePage: requestedReaderPage,
      ));

      // The requested page is ready and provider state is restored. Make the
      // reader interactive now; initial positioning must not keep the loading
      // overlay alive if ScrollablePositionedList is still attaching its controller.
      if (mounted) setState(() => _isInitializingReader = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_scrollToPage(requestedReaderPage, animated: false));
      });
    } catch (_) {
      // Do not leave the screen permanently blocked if bundled data is invalid.
      if (mounted) setState(() => _isInitializingReader = false);
    }
  }

  Future<QuranPage> _loadPage(int page, {bool prefetch = true}) async {
    final data = await _repository.loadPage(page);
    if (prefetch) _repository.prefetchAround(page);
    return data;
  }

  Future<QuranPage> _pageFuture(int page) {
    final existing = _pageFutures[page];
    if (existing != null) return existing;

    final future = _loadPage(page);
    _pageFutures[page] = future;
    // Keep the active neighborhood and a few upcoming requests. The repository
    // owns the decoded-page LRU cache; this map only deduplicates widget futures.
    while (_pageFutures.length > 32) {
      final removable = _pageFutures.keys.firstWhere(
        (key) => (key - _readerPage).abs() > 4,
        orElse: () => _pageFutures.keys.first,
      );
      _pageFutures.remove(removable);
    }
    return future;
  }

  Future<void> _scrollToPage(int page, {bool animated = true}) async {
    if (page < 1 || page > totalReaderPages || !mounted) return;

    final generation = ++_navigationGeneration;
    _isProgrammaticNavigation = true;

    if (_readerPage != page) {
      setState(() => _readerPage = page);
    }

    try {
      if (!_itemScrollController.isAttached) {
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!_itemScrollController.isAttached || !mounted ||
          generation != _navigationGeneration) {
        return;
      }

      // ScrollablePositionedList.scrollTo animates via estimated pixel offsets.
      // With variable-height Mushaf pages those estimates can drift badly during
      // a fast fling, landing dozens of items away. Indexed jumpTo targets the
      // requested item directly; reliability matters more than a short animation.
      _itemScrollController.jumpTo(index: page - 1, alignment: 0);

      // Let the indexed list apply the target and publish its final positions
      // before the position listener is allowed to update the page indicator.
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted || generation != _navigationGeneration) return;

      final targetIsVisible = _itemPositionsListener.itemPositions.value.any(
        (position) => position.index == page - 1,
      );
      if (!targetIsVisible && _itemScrollController.isAttached) {
        // One corrective indexed jump handles the first layout's stale
        // extent estimates without introducing another scrolling mechanism.
        _itemScrollController.jumpTo(index: page - 1, alignment: 0);
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
      }

      if (mounted && generation == _navigationGeneration) {
        _readerPage = page;
        _scheduleSaveLastPage(page);
        _repository.prefetchAround(page);
      }
    } finally {
      if (generation == _navigationGeneration) {
        _isProgrammaticNavigation = false;
      }
    }
  }

  void _handleItemPositionsChanged() {
    if (!mounted || _isInitializingReader || _isProgrammaticNavigation) {
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
      _scheduleSaveLastPage(page);
      _repository.prefetchAround(page, radius: 4);
    }
  }

  void _scheduleSaveLastPage(int page) {
    _pageSaveDebounce?.cancel();
    _pageSaveDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_storage.saveLastQuranPage(page));
    });
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

  void _handleAyahTap(Verse verse) {
    // A normal tap never changes the ayah color or opens the toolbar.
    // It pauses auto-scroll so the reader can resume from the current position.
    if (_autoScrollEnabled) _stopAutoScroll(interruptAnimation: true);
    _removeAyahToolbar();
  }

  void _handleAyahLongPress(Verse verse, Offset globalPosition) {
    // Long press selects the verse and opens its contextual actions, when enabled.
    if (_autoScrollEnabled) _stopAutoScroll(interruptAnimation: true);
    setState(() => _selectedAyahKey = verse.id);
    _removeAyahToolbar();
    if (_ayahToolbarEnabled) _showAyahToolbar(verse, globalPosition);
  }

  Future<void> _openSurahNavigator() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: Text(LocaleController.isArabic ? 'انتقال إلى سورة' : 'Navigate to surah'),
        message: Text(LocaleController.isArabic ? 'اختر سورة للانتقال إلى بدايتها' : 'Choose a surah to open its beginning'),
        actions: [
          for (var surah = 1; surah <= 114; surah++)
            CupertinoActionSheetAction(
              isDefaultAction: surah == _currentPageSurah,
              onPressed: () {
                Navigator.pop(popupContext);
                unawaited(_scrollToPage(quran.getPageNumber(surah, 1)));
              },
              child: Text(
                LocaleController.isArabic
                    ? '${surah.toString()} · ${quran.getSurahNameArabic(surah)}'
                    : '${surah.toString()}. ${quran.getSurahName(surah)}',
                textDirection: LocaleController.isArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: Text(LocaleController.isArabic ? 'إلغاء' : 'Cancel'),
        ),
      ),
    );
  }

  Future<void> _playSpecificAyah(Verse verse) async {
    final generation = ++_recitationGeneration;
    setState(() {
      _isRecitationLoading = true;
      _recitationQueue = <Verse>[verse];
      _recitationIndex = 0;
    });
    try {
      await _recitationPlayer.stop();
      await _playRecitationVerse(generation);
    } catch (_) {
      if (mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(LocaleController.isArabic ? 'تعذّر تشغيل التلاوة' : 'Unable to play recitation'),
            content: Text(LocaleController.isArabic ? 'تحقّق من اتصال الإنترنت ثم حاول مرة أخرى.' : 'Check your internet connection and try again.'),
            actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(dialogContext), child: Text(LocaleController.isArabic ? 'حسنًا' : 'OK'))],
          ),
        );
      }
    } finally {
      if (mounted && generation == _recitationGeneration) setState(() => _isRecitationLoading = false);
    }
  }

  void _enterMemorizationMode(Verse verse) {
    _removeAyahToolbar();
    _stopAutoScroll(interruptAnimation: true);
    setState(() {
      _memorizationMode = true;
      _memorizationVerse = verse;
      _selectedAyahKey = null;
      _bottomBarVisible = true;
    });
    unawaited(_saveMemorizationPosition(verse));
  }

  Future<void> _saveMemorizationPosition(Verse verse) async {
    await _storage.saveMemorizationSession(
      surah: verse.surahNumber,
      startAyah: 1,
      endAyah: quran.getVerseCount(verse.surahNumber),
      currentAyah: verse.ayahNumber,
    );
  }

  Future<void> _moveMemorizationAyah(int delta) async {
    if (_memorizationBusy || _memorizationVerse == null) return;
    final current = _memorizationVerse!;
    var surah = current.surahNumber;
    var ayah = current.ayahNumber + delta;
    if (ayah < 1) {
      if (surah == 1) return;
      surah--;
      ayah = quran.getVerseCount(surah);
    } else if (ayah > quran.getVerseCount(surah)) {
      if (surah == 114) return;
      surah++;
      ayah = 1;
    }
    final next = Verse(surahNumber: surah, ayahNumber: ayah, text: quran.getVerse(surah, ayah));
    setState(() => _memorizationVerse = next);
    await _saveMemorizationPosition(next);
    final page = quran.getPageNumber(surah, ayah);
    if (page != _readerPage) await _scrollToPage(page);
  }

  Future<void> _recordMemorization({required bool needsReview}) async {
    final verse = _memorizationVerse;
    if (verse == null || _memorizationBusy) return;
    setState(() => _memorizationBusy = true);
    final key = verse.id;
    final memorized = Set<String>.from(_memorizedAyahs);
    final review = Set<String>.from(_reviewAyahs);
    if (needsReview) {
      review.add(key);
      memorized.remove(key);
    } else {
      memorized.add(key);
      review.remove(key);
    }
    try {
      await _storage.saveMemorizedAyahs(memorized);
      await _storage.saveMemorizationReviewAyahs(review);
      if (!mounted) return;
      setState(() {
        _memorizedAyahs = memorized;
        _reviewAyahs = review;
        _memorizationBusy = false;
      });
      await _moveMemorizationAyah(1);
    } finally {
      if (mounted && _memorizationBusy) {
        setState(() => _memorizationBusy = false);
      }
    }
  }

  void _exitMemorizationMode() {
    setState(() {
      _memorizationMode = false;
      _memorizationVerse = null;
      _memorizationBusy = false;
    });
  }

  void _showAyahToolbar(Verse verse, Offset globalPosition) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;
    final local = overlayBox.globalToLocal(globalPosition);
    final screen = MediaQuery.sizeOf(context);
    final width = screen.width < 326 ? screen.width - 16.0 : 310.0;
    const height = 62.0;
    final left = (local.dx - width / 2).clamp(8.0, screen.width - width - 8.0).toDouble();
    final top = (local.dy - height - 18).clamp(90.0, screen.height - height - 95.0).toDouble();
    _ayahActionOverlay = OverlayEntry(builder: (overlayContext) => Positioned(left: left, top: top, width: width, child: Material(color: const Color(0x00000000), child: DecoratedBox(decoration: BoxDecoration(color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(overlayContext), borderRadius: BorderRadius.circular(22), border: Border.all(color: CupertinoColors.separator.resolveFrom(overlayContext).withValues(alpha: .45)), boxShadow: [BoxShadow(color: CupertinoColors.black.withValues(alpha: .18), blurRadius: 22, offset: const Offset(0, 8))]), child: SizedBox(height: height, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _AyahActionButton(icon: CupertinoIcons.text_quote, active: _showTranslation, label: LocaleController.isArabic ? 'ترجمة' : 'Translation', onPressed: () { setState(() => _showTranslation = !_showTranslation); _settingsService.saveTranslation(_showTranslation); _removeAyahToolbar(); }),
      _AyahActionButton(icon: _darkPage ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max, active: _darkPage, label: LocaleController.isArabic ? 'المظهر' : 'Theme', onPressed: () { setState(() => _darkPage = !_darkPage); _settingsService.saveDarkPage(_darkPage); _removeAyahToolbar(); }),
      _AyahActionButton(icon: CupertinoIcons.book, active: _tajweedMode, label: _tajweedMode ? (LocaleController.isArabic ? 'تجويد' : 'Tajweed') : (LocaleController.isArabic ? 'المدينة' : 'Madinah'), onPressed: () { setState(() => _tajweedMode = !_tajweedMode); _removeAyahToolbar(); }),
      _AyahActionButton(icon: CupertinoIcons.play_fill, active: false, label: LocaleController.isArabic ? 'استمع' : 'Play', onPressed: () { _removeAyahToolbar(); _playSpecificAyah(verse); }),
      _AyahActionButton(icon: _memorizedAyahs.contains(verse.id) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.bookmark, active: _memorizedAyahs.contains(verse.id), label: LocaleController.isArabic ? 'حفظ' : 'Memorize', onPressed: () => _enterMemorizationMode(verse)),
      _AyahActionButton(icon: CupertinoIcons.xmark, active: false, label: LocaleController.isArabic ? 'إغلاق' : 'Close', onPressed: _removeAyahToolbar),
    ]))))));
    overlay.insert(_ayahActionOverlay!);
  }

  void _removeAyahToolbar() { _ayahActionOverlay?.remove(); _ayahActionOverlay = null; }

  void _toggleAutoScroll() {
    if (_autoScrollEnabled) {
      _stopAutoScroll(interruptAnimation: true);
      return;
    }
    // A fresh generation invalidates any older scrollTo future that is still
    // unwinding. Repeated taps therefore never create competing scroll loops.
    final generation = ++_autoScrollGeneration;
    setState(() => _autoScrollEnabled = true);
    unawaited(_runAutoScroll(generation));
  }

  void _stopAutoScroll({required bool interruptAnimation}) {
    ++_autoScrollGeneration;
    if (_autoScrollEnabled && mounted) {
      setState(() => _autoScrollEnabled = false);
    }
    if (!interruptAnimation || !_itemScrollController.isAttached) return;

    // scrollTo has no public cancellation token. An indexed jump cancels its
    // active animation; resume starts from the page currently nearest the view.
    final visible = _itemPositionsListener.itemPositions.value
        .where((p) => p.index >= 0 && p.index < totalReaderPages &&
            p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1)
        .toList(growable: false);
    if (visible.isEmpty) return;
    final current = visible.reduce((left, right) {
      final leftCenter = (left.itemLeadingEdge + left.itemTrailingEdge) / 2;
      final rightCenter = (right.itemLeadingEdge + right.itemTrailingEdge) / 2;
      return (leftCenter - 0.5).abs() <= (rightCenter - 0.5).abs()
          ? left : right;
    });
    _itemScrollController.jumpTo(index: current.index, alignment: 0);
  }

  Future<void> _runAutoScroll(int generation) async {
    // Advance one page at a time with a linear, user-configurable duration.
    // The generation token makes pause/resume race-safe.
    while (mounted && _autoScrollEnabled &&
        generation == _autoScrollGeneration) {
      if (!_itemScrollController.isAttached) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }
      final visible = _itemPositionsListener.itemPositions.value
          .where((p) => p.index >= 0 && p.index < totalReaderPages &&
              p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1)
          .toList(growable: false);
      if (visible.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }
      final current = visible.reduce((left, right) {
        final leftCenter = (left.itemLeadingEdge + left.itemTrailingEdge) / 2;
        final rightCenter = (right.itemLeadingEdge + right.itemTrailingEdge) / 2;
        return (leftCenter - 0.5).abs() <= (rightCenter - 0.5).abs()
            ? left : right;
      });
      final targetIndex = current.index + 1;
      if (targetIndex >= totalReaderPages) {
        if (mounted && generation == _autoScrollGeneration) {
          setState(() => _autoScrollEnabled = false);
        }
        return;
      }
      try {
        await _itemScrollController.scrollTo(
          index: targetIndex,
          alignment: 0,
          duration: Duration(
            milliseconds: (_autoScrollSecondsPerPage * 1000).round(),
          ),
          curve: Curves.linear,
        );
      } catch (_) {
        if (!mounted || generation != _autoScrollGeneration) return;
      }
      if (!mounted || generation != _autoScrollGeneration) return;
    }
  }
  void _hideReaderChromeDuringScroll() {
    _chromeVisibilityTimer?.cancel();
    if (_readerChromeVisible && mounted) {
      setState(() => _readerChromeVisible = false);
    }
    _removeAyahToolbar();
  }

  void _scheduleReaderChromeRestore() {
    _chromeVisibilityTimer?.cancel();
    _chromeVisibilityTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && !_readerChromeVisible) {
        setState(() => _readerChromeVisible = true);
      }
    });
  }

  bool _handleReaderScrollNotification(ScrollNotification notification) {
    // Only direct user drags hide the chrome. Programmatic navigation and
    // auto-scroll should not cause controls to flash between pages.
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _hideReaderChromeDuringScroll();
      if (_autoScrollEnabled) {
        // Invalidate the auto-scroll loop when the reader takes manual control.
        // The active indexed animation is interrupted so it cannot fight the drag.
        _stopAutoScroll(interruptAnimation: true);
      }
    } else if (notification is ScrollEndNotification) {
      _scheduleReaderChromeRestore();
    }
    return false;
  }

  void _openReaderSettings() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => StatefulBuilder(
        builder: (popupContext, sheetSetState) {
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

          void updateAutoScrollSpeed(double value) {
            sheetSetState(() {});
            setState(() => _autoScrollSecondsPerPage = value);
            unawaited(_settingsService.saveAutoScrollSecondsPerPage(value));
          }

          return CupertinoActionSheet(
            title: Text(LocaleController.isArabic ? 'إعدادات المصحف' : 'Mushaf settings'),
            message: Column(
              children: [
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                Text(
                  LocaleController.isArabic
                      ? 'سرعة التمرير التلقائي: ${_autoScrollSecondsPerPage.round()} ثانية لكل صفحة'
                      : 'Auto-scroll speed: ${_autoScrollSecondsPerPage.round()} seconds per page',
                ),
                CupertinoSlider(
                  min: 10,
                  max: 60,
                  divisions: 10,
                  value: _autoScrollSecondsPerPage,
                  onChanged: updateAutoScrollSpeed,
                ),
                Text(
                  LocaleController.isArabic
                      ? 'حرّك المؤشر نحو اليسار للتمرير الأسرع'
                      : 'Faster scrolling uses fewer seconds per page.',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(popupContext),
                  ),
                  textAlign: TextAlign.center,
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
      navigationBar: _readerChromeVisible ? CupertinoNavigationBar(
        key: const ValueKey('quran-reader-app-bar'),
        middle: Text(LocaleController.isArabic ? 'القرآن الكريم' : 'The Holy Quran', style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _bottomBarVisible = !_bottomBarVisible),
          child: Icon(_bottomBarVisible ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_up),
        ),
      ) : null,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              top: _readerChromeVisible ? 48 : 0,
              bottom: _readerChromeVisible && _bottomBarVisible ? 74 : 0,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerUp,
                onPointerCancel: _handlePointerUp,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleReaderScrollNotification,
                  child: ScrollablePositionedList.builder(
                    key: const ValueKey('quran-reader-list'),
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    scrollDirection: Axis.vertical,
                    physics: const FixedSpeedScrollPhysics(),
                    itemCount: totalReaderPages,
                    itemBuilder: (context, index) {
                      final page = index + 1;
                      return FutureBuilder<QuranPage>(
                        future: _pageFuture(page),
                        // A prefetched/cached page renders immediately, avoiding
                        // a spinner flash when the user scrolls back or ahead.
                        initialData: _repository.cachedPage(page),
                        builder: (context, snapshot) {
                          final pageData = snapshot.data;
                          if (pageData != null) {
                            return _MushafPage(
                              key: ValueKey('quran-page-loaded-$page'),
                              page: page,
                              pageData: pageData,
                              fontSize: _fontSize,
                              lineHeight: _lineHeight,
                              showTranslation: _showTranslation,
                              darkPage: _darkPage,
                              selectedAyahKey: _selectedAyahKey,
                              onAyahTap: _handleAyahTap,
                              onAyahLongPress: _handleAyahLongPress,
                            );
                          }
                          if (snapshot.hasError) {
                            return _ErrorPage(
                              page: page,
                              onRetry: () {
                                _pageFutures.remove(page);
                                setState(() {});
                              },
                            );
                          }
                          return _MushafPagePlaceholder(darkPage: _darkPage);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_readerChromeVisible)
              Positioned(
              key: const ValueKey('quran-reader-header-navigator'),
              top: 0,
              left: 4,
              right: 4,
              height: 44,
              child: _MushafNavigationStrip(
                page: _readerPage,
                surah: _currentPageSurah,
                juz: _currentPageJuz,
                onPrevious: () => _scrollToPage(_readerPage - 1),
                onNext: () => _scrollToPage(_readerPage + 1),
                onChooseSurah: _openSurahNavigator,
              ),
            ),
            if (_readerChromeVisible && _bottomBarVisible)
              Positioned(
                key: const ValueKey('quran-reader-bottom-toolbar'),
                left: 8, right: 8, bottom: MediaQuery.paddingOf(context).bottom + 8,
                child: _memorizationMode && _memorizationVerse != null
                    ? _MemorizationBottomBar(
                        verse: _memorizationVerse!,
                        memorized: _memorizedAyahs.contains(_memorizationVerse!.id),
                        needsReview: _reviewAyahs.contains(_memorizationVerse!.id),
                        busy: _memorizationBusy,
                        onPrevious: () => _moveMemorizationAyah(-1),
                        onNext: () => _moveMemorizationAyah(1),
                        onMemorized: () => _recordMemorization(needsReview: false),
                        onReview: () => _recordMemorization(needsReview: true),
                        onClose: _exitMemorizationMode,
                      )
                    : _ReaderBottomBar(
                        isPlaying: _isRecitationPlaying, autoScrollEnabled: _autoScrollEnabled,
                        onPrevious: () => _scrollToPage(_readerPage - 1),
                        onNext: () => _scrollToPage(_readerPage + 1),
                        onJump: _openNavigator, onPlayPause: _toggleRecitation, onAutoScroll: _toggleAutoScroll,
                        onChooseReciter: _chooseReciter, onSearch: _searchQuran, onBookmark: _bookmarkCurrentPage, onSettings: _openReaderSettings,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}


class _MemorizationBottomBar extends StatelessWidget {
  const _MemorizationBottomBar({
    required this.verse,
    required this.memorized,
    required this.needsReview,
    required this.busy,
    required this.onPrevious,
    required this.onNext,
    required this.onMemorized,
    required this.onReview,
    required this.onClose,
  });

  final Verse verse;
  final bool memorized;
  final bool needsReview;
  final bool busy;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onMemorized;
  final VoidCallback onReview;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ar = LocaleController.isArabic;
    final status = memorized
        ? (ar ? 'محفوظة' : 'Memorized')
        : needsReview
            ? (ar ? 'تحتاج مراجعة' : 'Needs review')
            : (ar ? 'قيد الحفظ' : 'In progress');
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context).withValues(alpha: .98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: .5)),
        boxShadow: [BoxShadow(color: CupertinoColors.black.withValues(alpha: .14), blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Text(
            ar
              ? '${quran.getSurahNameArabic(verse.surahNumber)} · الآية ${verse.ayahNumber} · $status'
              : '${quran.getSurahName(verse.surahNumber)} · Ayah ${verse.ayahNumber} · $status',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: ar ? TextAlign.right : TextAlign.left,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          )),
          CupertinoButton(padding: const EdgeInsets.all(4), minimumSize: const Size(36, 36), onPressed: onClose, child: const Icon(CupertinoIcons.xmark_circle, size: 19)),
        ]),
        Row(children: [
          Expanded(child: _control(context, CupertinoIcons.chevron_left, ar ? 'السابق' : 'Previous', onPrevious)),
          Expanded(child: _control(context, CupertinoIcons.chevron_right, ar ? 'التالي' : 'Next', onNext)),
          Expanded(child: _control(context, CupertinoIcons.arrow_counterclockwise, ar ? 'مراجعة' : 'Review', onReview, active: needsReview, enabled: !busy)),
          Expanded(child: _control(context, CupertinoIcons.checkmark_circle_fill, ar ? 'حفظت' : 'Memorized', onMemorized, active: memorized, enabled: !busy)),
        ]),
      ]),
    );
  }

  Widget _control(BuildContext context, IconData icon, String label, VoidCallback action, {bool active = false, bool enabled = true}) {
    final foreground = active ? const Color(0xFF176B52) : CupertinoColors.label.resolveFrom(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      minimumSize: const Size(44, 44),
      onPressed: enabled ? action : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: foreground),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: foreground)),
      ]),
    );
  }
}

class _AyahActionButton extends StatelessWidget {
  const _AyahActionButton({required this.icon, required this.active, required this.label, required this.onPressed});
  final IconData icon; final bool active; final String label; final VoidCallback onPressed;
  @override Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5), minimumSize: const Size(42, 48),
    onPressed: onPressed,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 19, color: active ? const Color(0xFF176B52) : CupertinoColors.label.resolveFrom(context)),
      const SizedBox(height: 2),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8, color: active ? const Color(0xFF176B52) : CupertinoColors.secondaryLabel.resolveFrom(context))),
    ]),
  );
}

class _ReaderBottomBar extends StatelessWidget {
  const _ReaderBottomBar({required this.isPlaying, required this.autoScrollEnabled, required this.onPrevious, required this.onNext, required this.onJump, required this.onPlayPause, required this.onAutoScroll, required this.onChooseReciter, required this.onSearch, required this.onBookmark, required this.onSettings});
  final bool isPlaying, autoScrollEnabled;
  final VoidCallback onPrevious, onNext, onJump, onPlayPause, onAutoScroll, onChooseReciter, onSearch, onBookmark, onSettings;
  @override Widget build(BuildContext context) {
    final ar = LocaleController.isArabic;
    return Container(
    height: 58, padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context).withValues(alpha: .97), borderRadius: BorderRadius.circular(24), border: Border.all(color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: .45)), boxShadow: [BoxShadow(color: CupertinoColors.black.withValues(alpha: .12), blurRadius: 20, offset: const Offset(0, 6))]),
    child: Row(children: [
      _item(context, CupertinoIcons.chevron_up, ar ? 'السابق' : 'Previous', onPrevious),
      _item(context, CupertinoIcons.chevron_down, ar ? 'التالي' : 'Next', onNext),
      CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 5), minimumSize: const Size(35, 45), onPressed: onJump, child: const Icon(CupertinoIcons.list_number, size: 18)),
      _item(context, autoScrollEnabled ? CupertinoIcons.pause_circle_fill : CupertinoIcons.speedometer, ar ? 'تلقائي' : 'Auto', onAutoScroll, active: autoScrollEnabled),
      _item(context, isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, ar ? 'استمع' : 'Listen', onPlayPause, active: isPlaying),
      _item(context, CupertinoIcons.person_crop_circle, ar ? 'القارئ' : 'Reciter', onChooseReciter),
      _item(context, CupertinoIcons.search, ar ? 'بحث' : 'Search', onSearch),
      _item(context, CupertinoIcons.bookmark, ar ? 'حفظ' : 'Save', onBookmark),
      _item(context, CupertinoIcons.slider_horizontal_3, ar ? 'المظهر' : 'Style', onSettings),
    ]),
  );
  }
  Widget _item(BuildContext context, IconData icon, String label, VoidCallback action, {bool active = false}) => Expanded(child: CupertinoButton(padding: EdgeInsets.zero, minimumSize: const Size(0, 44), onPressed: action, child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 17, color: active ? const Color(0xFF176B52) : CupertinoColors.label.resolveFrom(context)), Text(label, maxLines: 1, style: TextStyle(fontSize: 8, color: active ? const Color(0xFF176B52) : CupertinoColors.secondaryLabel.resolveFrom(context)))])));
}

class _MushafPage extends StatefulWidget {
  const _MushafPage({
    super.key,
    required this.page,
    required this.pageData,
    required this.fontSize,
    required this.lineHeight,
    required this.showTranslation,
    required this.darkPage,
    required this.selectedAyahKey,
    required this.onAyahTap,
    required this.onAyahLongPress,
  });

  final int page;
  final QuranPage pageData;
  final double fontSize;
  final double lineHeight;
  final bool showTranslation;
  final bool darkPage;
  final String? selectedAyahKey;
  final ValueChanged<Verse> onAyahTap;
  final void Function(Verse verse, Offset globalPosition) onAyahLongPress;
  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  final Map<String, TapGestureRecognizer> _tapRecognizers = {};
  final Map<String, Timer> _longPressTimers = {};
  final Set<String> _longPressTriggered = <String>{};
  final Map<String, Offset> _pressPositions = {};

  @override
  void dispose() {
    for (final recognizer in _tapRecognizers.values) {
      recognizer.dispose();
    }
    for (final timer in _longPressTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  TapGestureRecognizer _tapRecognizerFor(String key, Verse verse) {
    final existing = _tapRecognizers[key];
    if (existing != null) return existing;
    final recognizer = TapGestureRecognizer()
      ..onTapDown = (details) {
        _longPressTimers.remove(key)?.cancel();
        _longPressTriggered.remove(key);
        _pressPositions[key] = details.globalPosition;
        _longPressTimers[key] = Timer(
          kLongPressTimeout,
          () {
            _longPressTimers.remove(key);
            final position = _pressPositions[key];
            if (!mounted || position == null) return;
            _longPressTriggered.add(key);
            widget.onAyahLongPress(verse, position);
          },
        );
      }
      ..onTap = () {
        _longPressTimers.remove(key)?.cancel();
        _pressPositions.remove(key);
        if (_longPressTriggered.remove(key)) return;
        widget.onAyahTap(verse);
      }
      ..onTapCancel = () {
        _longPressTimers.remove(key)?.cancel();
        _pressPositions.remove(key);
      };
    _tapRecognizers[key] = recognizer;
    return recognizer;
  }

  String _ayahKey(Verse verse) => verse.id;

  bool _isHighlighted(Verse verse) => widget.selectedAyahKey == _ayahKey(verse);

  List<Verse> get verses => widget.pageData.verses;

  String _verseText(Verse verse) => verse.displayText;

  @override
  Widget build(BuildContext context) {
    // Warm, book-like paper palette inspired by a printed Mushaf.
    final pageBg = widget.darkPage
        ? const Color(0xFF3A352F)
        : const Color(0xFFF6F0E4);
    final ink = widget.darkPage
        ? const Color(0xFFF0EDE6)
        : const Color(0xFF2D2924);
    final green = widget.darkPage
        ? const Color(0xFFC9C0A9)
        : const Color(0xFF6B705C);
    final divider = widget.darkPage
        ? const Color(0xFF8D8477)
        : const Color(0xFFC7BBA8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(5, 8, 5, 6),
      color: pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildSurahContent(ink: ink, green: green, divider: divider),
          const SizedBox(height: 4),
          _OrnamentalPageNumber(page: widget.page, color: green, divider: divider),
        ],
      ),
    );
  }

  List<Widget> _buildSurahContent({
    required Color ink,
    required Color green,
    required Color divider,
  }) {
    final sections = <Widget>[];
    var start = 0;
    while (start < verses.length) {
      var end = start + 1;
      while (end < verses.length &&
          verses[end].surahNumber == verses[start].surahNumber) {
        end++;
      }
      final sectionVerses = verses.sublist(start, end);
      final surah = sectionVerses.first.surahNumber;
      final startsSurah = sectionVerses.first.ayahNumber == 1;

      if (startsSurah) {
        sections.add(_SurahHeader(
          arabic: quran.getSurahNameArabic(surah),
          color: green,
          border: divider,
        ));
        // Al-Fatiha already contains the basmala as its first ayah. Do not
        // print a second copy there; At-Tawbah is the only surah without one.
        if (surah != 1 && surah != 9) {
          sections.add(Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 12),
            child: Text(
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
          ));
        } else {
          sections.add(const SizedBox(height: 10));
        }
      }

      sections.add(Directionality(
        textDirection: TextDirection.rtl,
        child: Text.rich(
          TextSpan(children: [
            for (final verse in sectionVerses) ...[
              TextSpan(
                text: '${_verseText(verse)} ',
                style: TextStyle(
                  fontFamily: kQuranFont,
                  fontFamilyFallback: const ['Noto Naskh Arabic', 'Arial', 'serif'],
                  fontSize: widget.fontSize,
                  height: widget.lineHeight,
                  color: _isHighlighted(verse)
                      ? const Color(0xFFFF9800)
                      : ink,
                  fontWeight: FontWeight.w400,
                ),
                recognizer: _tapRecognizerFor(_ayahKey(verse), verse),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _AyahMarker(
                  number: verse.ayahNumber,
                  color: widget.darkPage ? const Color(0xFFE6E0C8) : green,
                  darkPage: widget.darkPage,
                  selected: _isHighlighted(verse),
                  onTap: () => widget.onAyahTap(verse),
                  onLongPressStart: (details) => widget.onAyahLongPress(verse, details.globalPosition),
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
          ]),
          textAlign: TextAlign.justify,
        ),
      ));
      sections.add(const SizedBox(height: 10));
      start = end;
    }
    return sections;
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
    required this.selected,
    required this.onTap,
    required this.onLongPressStart,
  });

  final int number;
  final Color color;
  final bool darkPage;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<LongPressStartDetails> onLongPressStart;

  @override
  Widget build(BuildContext context) {
    final markerColor = selected ? const Color(0xFFFF9800) : (darkPage ? const Color(0xFFE6E0C8) : color);
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: markerColor, width: selected ? 2.0 : 1.1),
          ),
          child: Text(
            _arabicNumber(number),
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: kQuranFont,
              fontSize: 11,
              color: markerColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}


class _SurahHeader extends StatelessWidget {
  const _SurahHeader({
    required this.arabic,
    required this.color,
    required this.border,
  });

  final String arabic;
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
          const SizedBox(height: 7),
          Container(height: 1, color: border.withValues(alpha: .75)),
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

class _MushafNavigationStrip extends StatelessWidget {
  const _MushafNavigationStrip({
    required this.page,
    required this.surah,
    required this.juz,
    required this.onPrevious,
    required this.onNext,
    required this.onChooseSurah,
  });

  final int page;
  final int surah;
  final int juz;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onChooseSurah;

  @override
  Widget build(BuildContext context) {
    final foreground = CupertinoColors.label.resolveFrom(context);
    final border = CupertinoColors.separator.resolveFrom(context);
    final arabic = LocaleController.isArabic;
    return Row(
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(32, 40),
          onPressed: onPrevious,
          child: Icon(CupertinoIcons.chevron_left, color: foreground),
        ),
        Expanded(child: _pill(arabic ? 'الجزء $juz' : 'Juz $juz', border, foreground)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(_arabicNumber(page), style: TextStyle(fontSize: 19, color: foreground)),
        ),
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 40),
            onPressed: onChooseSurah,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: border.withValues(alpha: .65)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      arabic ? quran.getSurahNameArabic(surah) : quran.getSurahName(surah),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: foreground, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(CupertinoIcons.chevron_down, size: 12, color: foreground),
                ],
              ),
            ),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(32, 40),
          onPressed: onNext,
          child: Icon(CupertinoIcons.chevron_right, color: foreground),
        ),
      ],
    );
  }

  Widget _pill(String label, Color border, Color foreground) => Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: border.withValues(alpha: .65)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: TextStyle(color: foreground, fontSize: 14)),
  );
}

class _MushafPagePlaceholder extends StatelessWidget {
  const _MushafPagePlaceholder({required this.darkPage});

  final bool darkPage;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: darkPage ? const Color(0xFF3A352F) : const Color(0xFFF6F0E4),
    child: const SizedBox(width: double.infinity, height: 480),
  );
}

class _OrnamentalPageNumber extends StatelessWidget {
  const _OrnamentalPageNumber({
    required this.page,
    required this.color,
    required this.divider,
  });

  final int page;
  final Color color;
  final Color divider;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Container(height: 1, color: divider)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: divider, width: 1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            _arabicNumber(page),
            style: TextStyle(
              fontFamily: kQuranFont,
              fontSize: 20,
              color: color,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: divider)),
      ],
    ),
  );
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


/// Allows a Mushaf page to scroll internally only when its rendered content
/// is taller than the available page viewport. This preserves one-page swipe
/// navigation for ordinary pages while preventing large Arabic text or
/// translations from being clipped on smaller displays.
class OverflowAwarePageScrollView extends StatefulWidget {
  const OverflowAwarePageScrollView({
    super.key,
    required this.page,
    required this.child,
  });

  final int page;
  final Widget child;

  @override
  State<OverflowAwarePageScrollView> createState() =>
      _OverflowAwarePageScrollViewState();
}

class _OverflowAwarePageScrollViewState
    extends State<OverflowAwarePageScrollView> {
  final GlobalKey _contentKey = GlobalKey();
  double? _viewportHeight;
  bool _isOverflowing = false;

  void _measureContent(double viewportHeight) {
    if (_viewportHeight == viewportHeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final renderObject = _contentKey.currentContext?.findRenderObject();
        if (renderObject is! RenderBox || !renderObject.hasSize) return;
        final nextOverflowing = renderObject.size.height > viewportHeight + 1;
        if (nextOverflowing != _isOverflowing) {
          setState(() => _isOverflowing = nextOverflowing);
        }
      });
      return;
    }
    _viewportHeight = viewportHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = _contentKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final nextOverflowing = renderObject.size.height > viewportHeight + 1;
      if (nextOverflowing != _isOverflowing) {
        setState(() => _isOverflowing = nextOverflowing);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        _measureContent(viewportHeight);
        return SingleChildScrollView(
          key: ValueKey<String>('quran-page-scroll-${widget.page}'),
          physics: _isOverflowing
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: KeyedSubtree(
            key: _contentKey,
            child: widget.child,
          ),
        );
      },
    );
  }
}
