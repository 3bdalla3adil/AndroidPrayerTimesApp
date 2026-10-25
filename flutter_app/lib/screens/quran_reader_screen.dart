import 'dart:collection';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
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
import '../models/prayer_entry.dart';
import '../services/prayer_service.dart';
import '../services/app_routes.dart';

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
  bool _tajweedMode = false;
  String? _selectedAyahKey;
  Set<String> _memorizedAyahs = <String>{};
  double _scaleStartFontSize = 25;
  double _lastScrollPixels = 0;
  bool _prayerHeaderVisible = false;
  List<PrayerEntry> _prayerTimes = const <PrayerEntry>[];
  DateTime _clockNow = DateTime.now();
  Timer? _clockTimer;
  late final PrayerService _prayerService = PrayerService(_storage);
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
    _loadPrayerHeader();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _clockNow = DateTime.now());
    });
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
    _clockTimer?.cancel();
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

  Future<void> _loadPrayerHeader() async {
    try {
      final prayers = await _prayerService.today();
      if (!mounted) return;
      setState(() => _prayerTimes = prayers);
    } catch (_) {
      // Prayer details are optional in the reader; keep the Mushaf usable
      // when location or prayer-time settings have not been configured.
    }
  }

  PrayerEntry? get _nextPrayer {
    for (final prayer in _prayerTimes) {
      if (prayer.time.isAfter(_clockNow)) return prayer;
    }
    return null;
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
      _memorizedAyahs = memorizedAyahs;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _scrollToPage(requestedReaderPage, animated: false);
        if (mounted) {
          setState(() => _isInitializingReader = false);
        }
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

  Future<void> _handleAyahSelected(Verse verse) async {
    setState(() => _selectedAyahKey = verse.id);
    await _showAyahToolbar(verse);
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

  Future<void> _toggleMemorizedAyah(Verse verse) async {
    final key = verse.id;
    final values = Set<String>.from(_memorizedAyahs);
    if (!values.add(key)) values.remove(key);
    await _storage.saveMemorizedAyahs(values);
    if (mounted) setState(() => _memorizedAyahs = values);
  }

  Future<void> _showAyahToolbar(Verse verse) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoPopupSurface(
        child: SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, sheetSetState) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: CupertinoColors.systemGrey3.resolveFrom(context), borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(height: 10),
                  Text(LocaleController.isArabic ? 'الآية ${verse.ayahNumber} • ${quran.getSurahNameArabic(verse.surahNumber)}' : '${quran.getSurahName(verse.surahNumber)} • Ayah ${verse.ayahNumber}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  CupertinoListTile(title: Text(LocaleController.isArabic ? 'إظهار الترجمة' : 'Translation'), trailing: CupertinoSwitch(value: _showTranslation, onChanged: (value) { setState(() => _showTranslation = value); sheetSetState(() {}); _settingsService.saveTranslation(value); })),
                  CupertinoListTile(title: Text(LocaleController.isArabic ? 'الوضع الداكن' : 'Dark page'), trailing: CupertinoSwitch(value: _darkPage, onChanged: (value) { setState(() => _darkPage = value); sheetSetState(() {}); _settingsService.saveDarkPage(value); })),
                  CupertinoListTile(title: Text(LocaleController.isArabic ? 'التجويد / مصحف المدينة' : 'Tajweed / Madinah Mushaf'), subtitle: Text(_tajweedMode ? (LocaleController.isArabic ? 'التجويد' : 'Tajweed') : (LocaleController.isArabic ? 'مصحف المدينة' : 'Madinah Mushaf')), trailing: CupertinoSwitch(value: _tajweedMode, onChanged: (value) { setState(() => _tajweedMode = value); sheetSetState(() {}); })),
                  const SizedBox(height: 6),
                  CupertinoButton.filled(onPressed: () { Navigator.pop(popupContext); _playSpecificAyah(verse); }, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_isRecitationPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill), const SizedBox(width: 8), Text(LocaleController.isArabic ? 'استمع إلى الآية' : 'Play this ayah')])),
                  const SizedBox(height: 6),
                  CupertinoButton(onPressed: () async { await _toggleMemorizedAyah(verse); sheetSetState(() {}); }, child: Text(_memorizedAyahs.contains(verse.id) ? (LocaleController.isArabic ? 'إزالة علامة الحفظ' : 'Remove memorized mark') : (LocaleController.isArabic ? 'وضع علامة محفوظة' : 'Mark as memorized'))),
                  CupertinoButton(onPressed: () { Navigator.pop(popupContext); Navigator.of(context).pushNamed(AppRoutes.quranMemorization); }, child: Text(LocaleController.isArabic ? 'فتح تدريب الحفظ' : 'Open memorization practice')),
                  CupertinoButton(onPressed: () => Navigator.pop(popupContext), child: Text(LocaleController.isArabic ? 'إغلاق' : 'Close')),
                ],
              ),
            ),
          ),
        ),
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
            if (_prayerHeaderVisible && _nextPrayer != null)
              _ReaderPrayerHeader(prayer: _nextPrayer!, now: _clockNow),
            if (_showToolbar) _ReaderToolbar(
              onNavigate: _openNavigator,
              onSearch: _searchQuran,
              onSettings: _openReaderSettings,
              onBookmark: _bookmarkCurrentPage,
              page: _readerPage,
              totalPages: totalReaderPages,
            ),
            _QuranReaderControls(
              isPlaying: _isRecitationPlaying,
              isLoading: _isRecitationLoading,
              reciterName: _reciters[_selectedReciter]!,
              translationEnabled: _showTranslation,
              tajweedMode: _tajweedMode,
              onPlayPause: _toggleRecitation,
              onChooseReciter: _chooseReciter,
              onTranslationChanged: (value) {
                setState(() => _showTranslation = value);
                _settingsService.saveTranslation(value);
              },
              onMushafModeChanged: (value) => setState(() => _tajweedMode = value),
            ),
            if (_tajweedMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 7),
                child: Text(
                  LocaleController.isArabic
                      ? 'وضع التجويد محدد، لكن بيانات التجويد الملوّن غير مضمّنة في ملفات المصحف الحالية.'
                      : 'Tajweed selected. Rule-accurate color highlighting requires tagged Tajweed text, which is not included in the current offline page data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                ),
              ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (_) => _scaleStartFontSize = _fontSize,
                onScaleUpdate: (details) {
                  if (details.pointerCount < 2 || (details.scale - 1).abs() < 0.015) return;
                  final size = (_scaleStartFontSize * details.scale).clamp(20.0, 38.0);
                  if ((size - _fontSize).abs() < 0.25) return;
                  setState(() => _fontSize = size);
                  _settingsService.saveFontSize(size);
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      final pixels = notification.metrics.pixels;
                      final movingDown = pixels > _lastScrollPixels;
                      if ((pixels - _lastScrollPixels).abs() > 0.5 && movingDown != _prayerHeaderVisible) {
                        setState(() => _prayerHeaderVisible = movingDown);
                      }
                      _lastScrollPixels = pixels;
                    }
                    return false;
                  },
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    scrollDirection: Axis.vertical,
                    // Keep all 604 Mushaf pages in one continuous vertical
                    // scroll so a drag/fling naturally crosses page edges.
                    physics: const FixedSpeedScrollPhysics(),
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
                                selectedAyahKey: _selectedAyahKey,
                                onAyahTap: _handleAyahSelected,
                              );
                          },
                        );
                    },
                  ),
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


class _ReaderPrayerHeader extends StatelessWidget {
  const _ReaderPrayerHeader({required this.prayer, required this.now});
  final PrayerEntry prayer;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final remaining = prayer.time.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    final countdown = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Row(children: [
        Expanded(child: Text(countdown, textAlign: TextAlign.left, style: const TextStyle(fontFeatures: [], fontWeight: FontWeight.w700, fontSize: 15))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(LocaleController.isArabic ? 'الصلاة القادمة' : 'NEXT PRAYER', style: const TextStyle(fontSize: 9, letterSpacing: 1.0, color: CupertinoColors.secondaryLabel)), Text(LocaleController.isArabic ? prayer.arabicName : prayer.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))])),
      ]),
    );
  }
}

class _QuranReaderControls extends StatelessWidget {
  const _QuranReaderControls({
    required this.isPlaying, required this.isLoading, required this.reciterName,
    required this.translationEnabled, required this.tajweedMode,
    required this.onPlayPause, required this.onChooseReciter,
    required this.onTranslationChanged, required this.onMushafModeChanged,
  });
  final bool isPlaying, isLoading, translationEnabled, tajweedMode;
  final String reciterName;
  final VoidCallback onPlayPause, onChooseReciter;
  final ValueChanged<bool> onTranslationChanged, onMushafModeChanged;

  @override
  Widget build(BuildContext context) {
    final ar = LocaleController.isArabic;
    const accent = Color(0xFF176B52);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        border: Border(bottom: BorderSide(color: CupertinoColors.separator.resolveFrom(context))),
      ),
      child: Column(children: [
        Row(children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            color: accent,
            borderRadius: BorderRadius.circular(22),
            onPressed: isLoading ? null : onPlayPause,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isLoading)
                const CupertinoActivityIndicator(color: CupertinoColors.white, radius: 8)
              else
                Icon(isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                    size: 16, color: CupertinoColors.white),
              const SizedBox(width: 7),
              Text(isLoading ? (ar ? 'جارٍ التحميل' : 'Loading')
                  : isPlaying ? (ar ? 'إيقاف مؤقت' : 'Pause')
                  : (ar ? 'تشغيل التلاوة' : 'Play recitation'),
                style: const TextStyle(color: CupertinoColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            onPressed: onChooseReciter,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(CupertinoIcons.person_crop_circle, size: 17),
              const SizedBox(width: 5),
              Flexible(child: Text(reciterName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12))),
              const SizedBox(width: 3),
              const Icon(CupertinoIcons.chevron_down, size: 11),
            ]),
          )),
        ]),
        const SizedBox(height: 5),
        Row(children: [
          const Icon(CupertinoIcons.text_quote, size: 17),
          const SizedBox(width: 7),
          Expanded(child: Text(ar ? 'الترجمة الإنجليزية' : 'Translation',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          CupertinoSwitch(value: translationEnabled, onChanged: onTranslationChanged),
        ]),
        const SizedBox(height: 3),
        Row(children: [
          const Icon(CupertinoIcons.book, size: 17),
          const SizedBox(width: 7),
          Expanded(child: Text(ar ? 'نمط المصحف' : 'Mushaf mode',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          CupertinoSlidingSegmentedControl<bool>(
            groupValue: tajweedMode,
            padding: const EdgeInsets.all(3),
            children: {
              false: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(ar ? 'المدينة' : 'Madinah', style: const TextStyle(fontSize: 11))),
              true: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(ar ? 'التجويد' : 'Tajweed', style: const TextStyle(fontSize: 11))),
            },
            onValueChanged: (value) { if (value != null) onMushafModeChanged(value); },
          ),
        ]),
      ]),
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
  });

  final int page;
  final QuranPage pageData;
  final double fontSize;
  final double lineHeight;
  final bool showTranslation;
  final bool darkPage;
  final String? selectedAyahKey;
  final ValueChanged<Verse> onAyahTap;
  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  final Map<String, TapGestureRecognizer> _ayahRecognizers = {};

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

  bool _isHighlighted(Verse verse) => widget.selectedAyahKey == _ayahKey(verse);

  void _toggleHighlight(Verse verse) {
    widget.onAyahTap(verse);
  }

  List<Verse> get verses => widget.pageData.verses;

  String _verseText(Verse verse) => verse.displayText;

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
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
      color: pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildSurahContent(ink: ink, green: green, divider: divider),
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
          english: quran.getSurahName(surah),
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
                recognizer: _recognizerFor(
                  _ayahKey(verse),
                  () => _toggleHighlight(verse),
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _AyahMarker(
                  number: verse.ayahNumber,
                  color: widget.darkPage ? const Color(0xFFE6E0C8) : green,
                  darkPage: widget.darkPage,
                  selected: _isHighlighted(verse),
                  onTap: () => _toggleHighlight(verse),
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
  });

  final int number;
  final Color color;
  final bool darkPage;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final markerColor = selected ? const Color(0xFFFF9800) : (darkPage ? const Color(0xFFE6E0C8) : color);
    return GestureDetector(
      onTap: onTap,
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
            color: selected ? const Color(0x33FF9800) : null,
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
