import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
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
  static const totalReaderPages = totalQuranPages + 1;

  final _controller = ScrollController();
  final _pageKeys = <int, GlobalKey>{};
  final _storage = StorageService();
  final _cache = <int, Map<String, dynamic>>{};

  int _readerPage = 0;
  double _fontSize = 25;
  double _lineHeight = 1.75;
  bool _showTranslation = false;
  bool _showToolbar = true;
  bool _darkPage = false;

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
          widget.startingPage == null && widget.surahNumber == 1
              ? 0
              : requestedQuranPage.clamp(1, totalQuranPages).toInt();

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

  Future<Map<String, dynamic>> _loadPage(int page) async {
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

    // Keep the adjacent page warm for instant swiping.
    for (final adjacent in [page - 1, page + 1]) {
      if (adjacent >= 1 &&
          adjacent <= totalQuranPages &&
          !_cache.containsKey(adjacent)) {
        _loadPage(adjacent).ignore();
      }
    }

    return data;
  }

  Future<void> _scrollToPage(int page, {bool animated = true}) async {
    if (page < 0 || page >= totalReaderPages) return;
    final key = _keyForPage(page);
    final target = key.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        duration: animated ? const Duration(milliseconds: 320) : Duration.zero,
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
      return;
    }
    if (!_controller.hasClients) return;
    final viewport = _controller.position.viewportDimension;
    final offset = (page * viewport).clamp(0.0, _controller.position.maxScrollExtent);
    if (animated) {
      await _controller.animateTo(offset, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
    } else {
      _controller.jumpTo(offset);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final builtTarget = key.currentContext;
      if (builtTarget != null) {
        Scrollable.ensureVisible(builtTarget, duration: animated ? const Duration(milliseconds: 180) : Duration.zero, alignment: 0.02);
      }
    });
  }

  Future<void> _goToPage(int page) => _scrollToPage(page);

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

  Future<void> _rememberPage(int index) async {
    if (index < 1) return;
    await _storage.saveReaderPage(index);
    try {
      final data = await _loadPage(index);
      final verses = ((data['verses'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
      if (verses.isEmpty) return;
      final surah = (verses.first['surah_number'] as num?)?.toInt();
      final ayah = (verses.first['ayah_number'] as num?)?.toInt();
      if (surah != null && ayah != null) {
        await _storage.saveReaderPosition(surah, ayah);
        await _storage.addReadingHistory(surah, ayah);
      }
    } catch (_) {}
  }

  void _jumpToPage() {
    final input = TextEditingController(text: '${_readerPage == 0 ? 1 : _readerPage}');
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('الانتقال إلى صفحة'),
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
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('انتقال'),
            onPressed: () {
              final value = int.tryParse(input.text.trim());
              Navigator.pop(dialogContext);
              if (value != null) _goToPage(value.clamp(1, totalQuranPages).toInt());
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
            title: const Text('إعدادات المصحف'),
            message: Column(
              children: [
                const SizedBox(height: 8),
                Text('حجم الخط: ${_fontSize.round()}'),
                CupertinoSlider(
                  min: 20,
                  max: 38,
                  value: _fontSize,
                  onChanged: updateFontSize,
                ),
                Text('تباعد السطور: ${_lineHeight.toStringAsFixed(2)}'),
                CupertinoSlider(
                  min: 1.35,
                  max: 2.15,
                  value: _lineHeight,
                  onChanged: updateLineHeight,
                ),
                CupertinoListTile(
                  title: const Text('الترجمة الإنجليزية'),
                  trailing: CupertinoSwitch(
                    value: _showTranslation,
                    onChanged: updateTranslation,
                  ),
                ),
                CupertinoListTile(
                  title: const Text('صفحة داكنة'),
                  trailing: CupertinoSwitch(
                    value: _darkPage,
                    onChanged: updateDarkPage,
                  ),
                ),
              ],
            ),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(popupContext),
              child: const Text('إغلاق'),
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

    return CupertinoPageScaffold(
      backgroundColor: background,
      navigationBar: CupertinoNavigationBar(
        middle: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'القرآن الكريم',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              _readerPage == 0 ? 'صفحة الإهداء' : 'صفحة $_readerPage من $totalQuranPages',
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
              onJump: _jumpToPage,
              onSettings: _openReaderSettings,
              onBookmark: _bookmarkCurrentPage,
              page: _readerPage,
              totalPages: totalReaderPages,
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    final viewport = notification.metrics.viewportDimension;
                    if (viewport > 0) {
                      final estimated = (notification.metrics.pixels / viewport)
                          .round()
                          .clamp(0, totalReaderPages - 1);
                      if (estimated != _readerPage) {
                        setState(() => _readerPage = estimated);
                        _rememberPage(estimated);
                      }
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _controller,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: totalReaderPages,
                  itemBuilder: (context, index) {
                    final page = index;
                    if (page == 0) {
                      return KeyedSubtree(
                        key: _keyForPage(page),
                        child: const _DedicationPage(),
                      );
                    }
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
              onPrevious: () => _goToPage(_readerPage - 1),
              onNext: () => _goToPage(_readerPage + 1),
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
    required this.onJump,
    required this.onSettings,
    required this.onBookmark,
    required this.page,
    required this.totalPages,
  });

  final VoidCallback onJump;
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
            icon: CupertinoIcons.search,
            label: 'صفحة',
            onPressed: onJump,
          ),
          const SizedBox(width: 8),
          _ReaderButton(
            icon: CupertinoIcons.slider_horizontal_3,
            label: 'المظهر',
            onPressed: onSettings,
          ),
          _ReaderButton(
            icon: CupertinoIcons.bookmark,
            label: 'حفظ',
            onPressed: page > 0 ? onBookmark : () {},
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

class _DedicationPage extends StatelessWidget {
  const _DedicationPage();

  static const _arabicLines = <String>[
    'إلى والد زوجتي الغالي، وأمير قلبها،',
    'وصاحب الفضل بعد الله في نشأتها وتربيتها،',
    'أُهدي إليك هذه الكلمات محبةً وتقديرًا،',
    'عرفانًا بمكانتك، وامتنانًا لثقتك الغالية.',
    'لقد أكرمني الله بزواجي من ابنتك،',
    'وأسأله أن يجعلني لها زوجًا صالحًا وسندًا أمينًا،',
    'وأن أُحسن صحبتها، وأصون قلبها،',
    'وأكون سببًا في سعادتها وراحة بالها.',
    'بارك الله في عمرك وصحتك، وأقرّ عينك بها،',
    'وجزاك عن تربيتها خير الجزاء،',
    'وجمعنا دائمًا على المحبة والمودة والرحمة.',
    'إهداءٌ من القلب، تقديرًا لمقامك ووفاءً لفضلك.',
  ];

  static const _englishLines = <String>[
    'To my beloved father-in-law, the prince of her heart,',
    'and the one who lovingly raised the daughter I am blessed to marry.',
    'I offer these words with sincere love, respect, and gratitude,',
    'in appreciation of your place in our family and your trust in me.',
    'Allah has honoured me by joining my life with your daughter.',
    'I pray to be a good husband and a steadfast companion to her,',
    'to cherish her heart, honour her, and care for her,',
    'and to be a source of happiness and peace in her life.',
    'May Allah bless your life and health and bring you joy through her,',
    'reward you abundantly for all you have given her,',
    'and keep our family united in love, mercy, and kindness.',
    'A heartfelt dedication, in honour of you and with lasting gratitude.',
  ];

  @override
  Widget build(BuildContext context) {
    final arabic = LocaleController.isArabic;
    final lines = arabic ? _arabicLines : _englishLines;
    return Container(
      margin: const EdgeInsets.fromLTRB(7, 8, 7, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        border: Border.all(color: const Color(0xFFD8C89C), width: 1),
        boxShadow: const [
          BoxShadow(blurRadius: 7, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 34),
            child: Directionality(
              textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('۞', style: TextStyle(fontFamily: 'serif', fontSize: 22, color: Color(0xFF6F6242))),
                  const SizedBox(height: 28),
                  Text(
                    arabic ? 'إهداء وتقدير' : 'A Dedication of Love & Gratitude',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: arabic ? 24 : 21,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF356B49),
                    ),
                  ),
                  const SizedBox(height: 26),
                  for (var i = 0; i < lines.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == lines.length - 1 ? 0 : 9),
                      child: Text(
                        lines[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: arabic ? 19 : 15,
                          height: arabic ? 1.35 : 1.5,
                          fontWeight: i < 2 ? FontWeight.w700 : FontWeight.w500,
                          color: const Color(0xFF242019),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  const Text('۞', style: TextStyle(fontFamily: 'serif', fontSize: 22, color: Color(0xFF6F6242))),
                ],
              ),
            ),
          ),
        ),
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

  Future<void> _toggleHighlight(Map<String, dynamic> verse) async {
    final key = _ayahKey(verse);
    final surah = (verse['surah_number'] as num?)?.toInt();
    final ayah = (verse['ayah_number'] as num?)?.toInt();
    setState(() {
      _highlightedAyah = _highlightedAyah == key ? null : key;
    });
    if (surah != null && ayah != null) {
      await StorageService().saveReaderPosition(surah, ayah);
      await StorageService().saveReaderPage(widget.page);
    }
  }

  Future<void> _restoreHighlight() async {
    final (surah, ayah) = await StorageService().loadReaderPosition();
    if (!mounted || surah == null || ayah == null) return;
    final match = verses.any((verse) =>
        (verse['surah_number'] as num?)?.toInt() == surah &&
        (verse['ayah_number'] as num?)?.toInt() == ayah);
    if (match) setState(() => _highlightedAyah = '$surah:$ayah');
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreHighlight());
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = widget.darkPage
        ? const Color(0xFF17211C)
        : const Color(0xFFFFFDF5);
    final ink = widget.darkPage
        ? const Color(0xFFECE8D9)
        : const Color(0xFF1B241E);
    final green = widget.darkPage
        ? const Color(0xFF9CC8A8)
        : const Color(0xFF356B49);
    final border = widget.darkPage
        ? const Color(0xFF50675A)
        : const Color(0xFFB8A66A);

    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: pageBg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: border, width: 1.1),
          boxShadow: const [
            BoxShadow(
              blurRadius: 7,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
          child: Column(
            children: [
              _PageOrnament(
                page: widget.page,
                color: green,
                border: border,
              ),
              if (_startsSurah) ...[
                const SizedBox(height: 10),
                _SurahHeader(
                  arabic: quran.getSurahNameArabic(_firstSurah),
                  english: quran.getSurahName(_firstSurah),
                  color: green,
                  border: border,
                ),
              ],
              if (_hasBasmala) ...[
                const SizedBox(height: 10),
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kQuranFont,
                    fontFamilyFallback: const ['Noto Naskh Arabic', 'Arial', 'serif'],
                    fontSize: widget.fontSize - 2,
                    height: 1.5,
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 11),
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
                                    : const Color(0xFF0B7A53))
                                : ink,
                            backgroundColor: _isHighlighted(verse)
                                ? (widget.darkPage
                                    ? const Color(0x334CAF50)
                                    : const Color(0x332E8B57))
                                : null,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: _recognizerFor(
                            _ayahKey(verse),
                            () => _toggleHighlight(verse),
                          ),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _AyahMarker(
                            number:
                                (verse['ayah_number'] as num?)?.toInt() ?? 0,
                            color: green,
                            darkPage: widget.darkPage,
                            onTap: () {
                              final surah =
                                  (verse['surah_number'] as num?)?.toInt();
                              final ayah =
                                  (verse['ayah_number'] as num?)?.toInt();
                              if (surah != null && ayah != null) {
                                widget.onBookmarkAyah(surah, ayah);
                              }
                            },
                          ),
                        ),
                        if (widget.showTranslation)
                          TextSpan(
                            text:
                                '\n${_translation(verse)}\n',
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
              Container(
                height: 1,
                color: border.withValues(alpha: .45),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.page}',
                style: TextStyle(
                  fontSize: 11,
                  color: green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
      child: Container(
        width: 25,
        height: 25,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: .7), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          _arabicNumber(number),
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: kQuranFont,
            fontSize: 9,
            color: darkPage ? const Color(0xFFE6E0C8) : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PageOrnament extends StatelessWidget {
  const _PageOrnament({
    required this.page,
    required this.color,
    required this.border,
  });

  final int page;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '۞',
            style: TextStyle(color: color, fontSize: 18),
          ),
        ),
        Text(
          '$page',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '۞',
            style: TextStyle(color: color, fontSize: 18),
          ),
        ),
        Expanded(child: Container(height: 1, color: border)),
      ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: .8),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Text(
            arabic,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: kQuranFont,
              fontFamilyFallback: const ['Noto Naskh Arabic', 'Arial', 'serif'],
              fontSize: 21,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            english,
            style: TextStyle(
              fontSize: 9,
              color: color.withValues(alpha: .8),
            ),
          ),
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
            onPressed: page > 0 ? onPrevious : null,
            child: const Icon(CupertinoIcons.chevron_left),
          ),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              onPressed: onJump,
              child: Text(
                'صفحة $page / $totalPages',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: page < totalPages - 1 ? onNext : null,
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
        child: Text('إعادة تحميل الصفحة $page'),
      ),
    );
  }
}
