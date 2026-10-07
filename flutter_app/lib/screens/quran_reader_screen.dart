import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../services/storage_service.dart';

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
  static const totalPages = 604;

  final _controller = PageController();
  final _storage = StorageService();
  final _cache = <int, Map<String, dynamic>>{};

  int _page = 1;
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
      final requested = widget.startingPage ??
          (starts[widget.surahNumber.toString()] as num?)?.toInt() ??
          1;

      if (!mounted) return;
      setState(() {
        _page = requested.clamp(1, totalPages);
        _fontSize = saved.clamp(20, 38);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.jumpToPage(_page - 1);
        }
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
          adjacent <= totalPages &&
          !_cache.containsKey(adjacent)) {
        _loadPage(adjacent).ignore();
      }
    }

    return data;
  }

  Future<void> _goToPage(int page) async {
    if (page < 1 || page > totalPages || !_controller.hasClients) return;
    await _controller.animateToPage(
      page - 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpToPage() {
    final input = TextEditingController(text: '$_page');
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
              if (value != null) _goToPage(value);
            },
          ),
        ],
      ),
    );
  }

  void _openReaderSettings() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: const Text('إعدادات المصحف'),
        message: Column(
          children: [
            const SizedBox(height: 8),
            Text('حجم الخط: ${_fontSize.round()}'),
            CupertinoSlider(
              min: 20,
              max: 38,
              value: _fontSize,
              onChanged: (value) {
                setState(() => _fontSize = value);
                _storage.saveQuranFontSize(value);
              },
            ),
            Text('تباعد السطور: ${_lineHeight.toStringAsFixed(2)}'),
            CupertinoSlider(
              min: 1.35,
              max: 2.15,
              value: _lineHeight,
              onChanged: (value) => setState(() => _lineHeight = value),
            ),
            CupertinoListTile(
              title: const Text('الترجمة الإنجليزية'),
              trailing: CupertinoSwitch(
                value: _showTranslation,
                onChanged: (value) =>
                    setState(() => _showTranslation = value),
              ),
            ),
            CupertinoListTile(
              title: const Text('صفحة داكنة'),
              trailing: CupertinoSwitch(
                value: _darkPage,
                onChanged: (value) => setState(() => _darkPage = value),
              ),
            ),
          ],
        ),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: const Text('إغلاق'),
        ),
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
              'صفحة $_page من $totalPages',
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
              page: _page,
              totalPages: totalPages,
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                reverse: true,
                itemCount: totalPages,
                onPageChanged: (index) =>
                    setState(() => _page = index + 1),
                itemBuilder: (context, index) {
                  final page = index + 1;
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _loadPage(page),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState !=
                          ConnectionState.done) {
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
                      );
                    },
                  );
                },
              ),
            ),
            _PageControls(
              page: _page,
              totalPages: totalPages,
              onPrevious: () => _goToPage(_page - 1),
              onNext: () => _goToPage(_page + 1),
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
    required this.page,
    required this.totalPages,
  });

  final VoidCallback onJump;
  final VoidCallback onSettings;
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
      minSize: 0,
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

class _MushafPage extends StatelessWidget {
  const _MushafPage({
    required this.page,
    required this.data,
    required this.fontSize,
    required this.lineHeight,
    required this.showTranslation,
    required this.darkPage,
  });

  final int page;
  final Map<String, dynamic> data;
  final double fontSize;
  final double lineHeight;
  final bool showTranslation;
  final bool darkPage;

  List<Map<String, dynamic>> get verses =>
      ((data['verses'] as List?) ?? const [])
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
    final pageBg = darkPage
        ? const Color(0xFF17211C)
        : const Color(0xFFFFFDF5);
    final ink = darkPage
        ? const Color(0xFFECE8D9)
        : const Color(0xFF1B241E);
    final green = darkPage
        ? const Color(0xFF9CC8A8)
        : const Color(0xFF356B49);
    final border = darkPage
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
                page: page,
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
                    fontFamily: 'serif',
                    fontSize: fontSize - 2,
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
                            fontFamily: 'serif',
                            fontSize: fontSize,
                            height: lineHeight,
                            color: ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _AyahMarker(
                            number:
                                (verse['ayah_number'] as num?)?.toInt() ?? 0,
                            color: green,
                            darkPage: darkPage,
                          ),
                        ),
                        if (showTranslation)
                          TextSpan(
                            text:
                                '\n${_translation(verse)}\n',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 13,
                              height: 1.45,
                              color: darkPage
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
                color: border.withOpacity(.45),
              ),
              const SizedBox(height: 6),
              Text(
                '$page',
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
              fontFamily: 'serif',
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
              color: color.withOpacity(.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahMarker extends StatelessWidget {
  const _AyahMarker({
    required this.number,
    required this.color,
    required this.darkPage,
  });

  final int number;
  final Color color;
  final bool darkPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(.7), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        quran.convertNumberToArabic(number),
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 9,
          color: darkPage ? const Color(0xFFE6E0C8) : color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
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
                'صفحة $page / $totalPages',
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
        child: Text('إعادة تحميل الصفحة $page'),
      ),
    );
  }
}
