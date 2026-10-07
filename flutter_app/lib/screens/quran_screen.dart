import 'package:flutter/cupertino.dart';
import 'package:quran/quran.dart' as quran;

import 'quran_reader_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String _query = '';

  List<int> get _items {
    final query = _query.trim().toLowerCase();
    final all = List.generate(quran.totalSurahCount, (i) => i + 1);
    if (query.isEmpty) return all;
    return all.where((number) {
      final text = '${quran.getSurahName(number)} ${quran.getSurahNameArabic(number)}';
      return text.toLowerCase().contains(query) || number.toString() == query;
    }).toList();
  }

  void _openReader(int surah, {int ayah = 1, int? page}) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => QuranReaderScreen(
          surahNumber: surah,
          startingAyah: ayah,
          startingPage: page,
        ),
      ),
    );
  }

  Future<int?> _numberDialog({
    required String title,
    required String placeholder,
    required int min,
    required int max,
  }) async {
    final controller = TextEditingController();
    final value = await showCupertinoDialog<int>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            placeholder: placeholder,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= min && parsed <= max) {
                Navigator.pop(dialogContext, parsed);
              }
            },
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _navigateByPage() async {
    final page = await _numberDialog(
      title: 'الانتقال حسب الصفحة',
      placeholder: '1 - 604',
      min: 1,
      max: 604,
    );
    if (page == null) return;
    final data = quran.getPageData(page);
    if (data.isEmpty) return;
    final first = data.first;
    final surah = (first['surah'] as num?)?.toInt() ?? 1;
    final ayah = (first['start'] as num?)?.toInt() ?? 1;
    _openReader(surah, ayah: ayah, page: page);
  }

  Future<void> _navigateByJuz() async {
    final juz = await _numberDialog(
      title: 'الانتقال حسب الجزء',
      placeholder: '1 - 30',
      min: 1,
      max: 30,
    );
    if (juz == null) return;
    final verses = quran.getSurahAndVersesFromJuz(juz);
    if (verses.isEmpty) return;
    final surahs = verses.keys.toList()..sort();
    final firstSurah = surahs.first;
    final firstAyah = verses[firstSurah]?.first ?? 1;
    _openReader(
      firstSurah,
      ayah: firstAyah,
      page: quran.getPageNumber(firstSurah, firstAyah),
    );
  }

  Future<void> _navigateByAyah() async {
    final surah = await _numberDialog(
      title: 'رقم السورة',
      placeholder: '1 - 114',
      min: 1,
      max: 114,
    );
    if (surah == null) return;
    final ayah = await _numberDialog(
      title: 'رقم الآية — ${quran.getSurahNameArabic(surah)}',
      placeholder: '1 - ${quran.getVerseCount(surah)}',
      min: 1,
      max: quran.getVerseCount(surah),
    );
    if (ayah == null) return;
    _openReader(
      surah,
      ayah: ayah,
      page: quran.getPageNumber(surah, ayah),
    );
  }

  Future<void> _openNavigator() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: const Text('تنقّل في القرآن'),
        message: const Text('السورة والآية والصفحة والجزء'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(popupContext);
              _navigateByJuz();
            },
            child: const Text('حسب الجزء (30 جزءًا)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(popupContext);
              _navigateByPage();
            },
            child: const Text('حسب الصفحة (604 صفحات)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(popupContext);
              _navigateByAyah();
            },
            child: const Text('حسب السورة والآية'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('القرآن الكريم'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _openNavigator,
          child: const Icon(CupertinoIcons.arrow_right_arrow_left),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  CupertinoSearchTextField(
                    placeholder: 'Search surah',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton.filled(
                    onPressed: _openNavigator,
                    child: const Text('تنقّل: سورة • آية • صفحة • جزء'),
                  ),
                  const SizedBox(height: 12),
                  CupertinoListSection.insetGrouped(
                    children: [
                      for (final number in items)
                        CupertinoListTile(
                          leading: _NumberBadge(number: number),
                          title: Text(quran.getSurahName(number)),
                          subtitle: Text(
                            '${quran.getPlaceOfRevelation(number)} • ${quran.getVerseCount(number)} verses',
                          ),
                          trailing: Text(
                            quran.getSurahNameArabic(number),
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontFamily: 'serif', fontSize: 17),
                          ),
                          onTap: () => _openReader(number),
                        ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CupertinoColors.activeGreen.resolveFrom(context),
        ),
        alignment: Alignment.center,
        child: Text(
          number.toString(),
          style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w700),
        ),
      );
}
