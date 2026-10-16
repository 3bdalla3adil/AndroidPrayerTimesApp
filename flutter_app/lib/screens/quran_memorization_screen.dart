import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:quran/quran.dart' as quran;

import '../core/adaptive_page_scaffold.dart';
import '../services/locale_controller.dart';
import '../services/storage_service.dart';

/// Offline, Arabic-only Hifz practice. Progress is saved locally on the device.
class QuranMemorizationScreen extends StatefulWidget {
  const QuranMemorizationScreen({super.key});

  @override
  State<QuranMemorizationScreen> createState() => _QuranMemorizationScreenState();
}

class _QuranMemorizationScreenState extends State<QuranMemorizationScreen> {
  final _storage = StorageService();
  int _surah = 1;
  int _startAyah = 1;
  int _endAyah = 7;
  int _currentAyah = 1;
  bool _showAyah = false;
  bool _loading = true;
  Set<String> _memorized = <String>{};
  Set<String> _review = <String>{};

  bool get _arabic => LocaleController.isArabic;
  int get _verseCount => quran.getVerseCount(_surah);
  String _key(int surah, int ayah) => '$surah:$ayah';
  bool get _isMemorized => _memorized.contains(_key(_surah, _currentAyah));
  bool get _needsReview => _review.contains(_key(_surah, _currentAyah));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memorized = await _storage.loadMemorizedAyahs();
    final review = await _storage.loadMemorizationReviewAyahs();
    final session = await _storage.loadMemorizationSession();
    final surah = (session['surah'] ?? 1).clamp(1, 114).toInt();
    final count = quran.getVerseCount(surah);
    final start = (session['start'] ?? 1).clamp(1, count).toInt();
    final end = (session['end'] ?? (start + 6).clamp(1, count)).clamp(start, count).toInt();
    final current = (session['current'] ?? start).clamp(start, end).toInt();
    if (!mounted) return;
    setState(() {
      _memorized = memorized;
      _review = review;
      _surah = surah;
      _startAyah = start;
      _endAyah = end;
      _currentAyah = current;
      _loading = false;
    });
  }

  Future<void> _saveSession() => _storage.saveMemorizationSession(
        surah: _surah,
        startAyah: _startAyah,
        endAyah: _endAyah,
        currentAyah: _currentAyah,
      );

  Future<void> _chooseSurah() async {
    var selected = _surah;
    final result = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => Container(
        height: 320,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_arabic ? 'إلغاء' : 'Cancel'),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context, selected),
                    child: Text(_arabic ? 'اختيار' : 'Select'),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: _surah - 1),
                  itemExtent: 42,
                  onSelectedItemChanged: (index) => selected = index + 1,
                  children: [
                    for (var number = 1; number <= 114; number++)
                      Center(
                        child: Text(
                          '${number.toString().padLeft(3, '0')}  ${quran.getSurahNameArabic(number)}  •  ${quran.getSurahName(number)}',
                          textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    final count = quran.getVerseCount(result);
    setState(() {
      _surah = result;
      _startAyah = 1;
      _endAyah = count < 7 ? count : 7;
      _currentAyah = 1;
      _showAyah = false;
    });
    await _saveSession();
  }

  Future<int?> _askAyah(String title, int initial) async {
    final controller = TextEditingController(text: initial.toString());
    final value = await showCupertinoDialog<int>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            placeholder: '1 - $_verseCount',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_arabic ? 'إلغاء' : 'Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value >= 1 && value <= _verseCount) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: Text(_arabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _chooseRange() async {
    final start = await _askAyah(_arabic ? 'أول آية' : 'First ayah', _startAyah);
    if (start == null || !mounted) return;
    final end = await _askAyah(_arabic ? 'آخر آية' : 'Last ayah', _endAyah);
    if (end == null || !mounted || end < start) {
      if (mounted && end != null && end < start) {
        _message(_arabic ? 'آخر آية يجب أن تكون بعد أول آية' : 'Last ayah must not be before first ayah');
      }
      return;
    }
    setState(() {
      _startAyah = start;
      _endAyah = end;
      _currentAyah = start;
      _showAyah = false;
    });
    await _saveSession();
  }

  Future<void> _moveTo(int ayah) async {
    if (ayah < _startAyah || ayah > _endAyah) return;
    setState(() {
      _currentAyah = ayah;
      _showAyah = false;
    });
    await _saveSession();
  }

  Future<void> _markMemorized() async {
    final key = _key(_surah, _currentAyah);
    setState(() {
      _memorized.add(key);
      _review.remove(key);
      _showAyah = false;
    });
    await _storage.saveMemorizedAyahs(_memorized);
    await _storage.saveMemorizationReviewAyahs(_review);
    if (_currentAyah < _endAyah) {
      await _moveTo(_currentAyah + 1);
    } else {
      await _saveSession();
      if (mounted) _message(_arabic ? 'أحسنت! انتهيت من هذا المقطع.' : 'Well done! You finished this passage.');
    }
  }

  Future<void> _markForReview() async {
    final key = _key(_surah, _currentAyah);
    setState(() {
      _review.add(key);
      _memorized.remove(key);
      _showAyah = false;
    });
    await _storage.saveMemorizationReviewAyahs(_review);
    await _storage.saveMemorizedAyahs(_memorized);
    await _saveSession();
    if (_currentAyah < _endAyah) await _moveTo(_currentAyah + 1);
  }

  void _message(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_arabic ? 'حسنًا' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedInRange = List<int>.generate(
      _endAyah - _startAyah + 1,
      (index) => _startAyah + index,
    ).where((ayah) => _memorized.contains(_key(_surah, ayah))).length;
    final rangeCount = _endAyah - _startAyah + 1;
    final verseText = quran.getVerse(_surah, _currentAyah);
    final statusColor = _isMemorized
        ? const Color(0xFF18794E)
        : _needsReview
            ? const Color(0xFFB7791F)
            : CupertinoColors.secondaryLabel.resolveFrom(context);

    return AdaptivePageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_arabic ? 'حفظ القرآن' : 'Quran memorization'),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF104B3D), Color(0xFF071F1A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _arabic ? 'خطوة صغيرة كل يوم' : 'A little every day',
                          style: const TextStyle(color: Color(0xFFFFE7A3), fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _arabic
                              ? 'المحفوظ: ${_memorized.length} آية • للمراجعة: ${_review.length} آية'
                              : 'Memorized: ${_memorized.length} ayahs • To review: ${_review.length}',
                          style: const TextStyle(color: CupertinoColors.white, height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: material.LinearProgressIndicator(
                            value: (_memorized.length / 6236).clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: const Color(0xFF47675C),
                            valueColor: const material.AlwaysStoppedAnimation<Color>(Color(0xFFFFE7A3)),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${((_memorized.length / 6236) * 100).toStringAsFixed(1)}% ${_arabic ? 'من آيات القرآن' : 'of Quran ayahs'}',
                          style: const TextStyle(color: Color(0xFFD6E3DB), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoListSection.insetGrouped(
                    header: Text(_arabic ? 'خطة الحفظ' : 'MEMORIZATION PLAN'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.book_fill),
                        title: Text(_arabic ? quran.getSurahNameArabic(_surah) : quran.getSurahName(_surah)),
                        subtitle: Text('${quran.getSurahName(_surah)} • ${_arabic ? 'السورة' : 'Surah'} $_surah'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _chooseSurah,
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.list_number),
                        title: Text(_arabic ? 'نطاق الآيات' : 'Ayah range'),
                        subtitle: Text('$_startAyah – $_endAyah  •  $rangeCount ${_arabic ? 'آيات' : 'ayahs'}'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _chooseRange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(_arabic ? 'تقدّم المقطع' : 'Passage progress', style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text('$completedInRange / $rangeCount'),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: material.LinearProgressIndicator(value: completedInRange / rangeCount, minHeight: 6),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: .45)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_arabic ? 'الآية' : 'Ayah'} $_currentAyah / $_endAyah',
                          style: const TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        if (_showAyah)
                          Text(
                            verseText,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'KFGQPC HAFS Uthmanic Script', fontSize: 28, height: 2, color: Color(0xFF176B52)),
                          )
                        else
                          Column(
                            children: [
                              const Icon(CupertinoIcons.eye_slash, size: 34, color: CupertinoColors.secondaryLabel),
                              const SizedBox(height: 8),
                              Text(
                                _arabic ? 'حاول تذكّر الآية قبل إظهارها' : 'Recall the ayah before revealing it',
                                textAlign: TextAlign.center,
                                style: const TextStyle(height: 1.5),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _isMemorized
                              ? (_arabic ? 'محفوظة بإتقان' : 'Marked memorized')
                              : _needsReview
                                  ? (_arabic ? 'تحتاج إلى مراجعة' : 'Needs review')
                                  : (_arabic ? 'لم تُقيّم بعد' : 'Not reviewed yet'),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton.filled(
                            onPressed: () => setState(() => _showAyah = !_showAyah),
                            child: Text(_showAyah ? (_arabic ? 'إخفاء الآية' : 'Hide ayah') : (_arabic ? 'إظهار الآية' : 'Reveal ayah')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          onPressed: _currentAyah > _startAyah ? () => _moveTo(_currentAyah - 1) : null,
                          child: Text(_arabic ? 'السابقة' : 'Previous'),
                        ),
                      ),
                      Expanded(
                        child: CupertinoButton(
                          onPressed: _currentAyah < _endAyah ? () => _moveTo(_currentAyah + 1) : null,
                          child: Text(_arabic ? 'التالية' : 'Next'),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          onPressed: _markForReview,
                          child: Text(_arabic ? 'تحتاج مراجعة' : 'Needs review'),
                        ),
                      ),
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: _markMemorized,
                          child: Text(_arabic ? 'حفظت الآية' : 'Memorized'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    onPressed: () => _moveTo(_startAyah),
                    child: Text(_arabic ? 'البدء من أول المقطع' : 'Restart passage'),
                  ),
                ],
              ),
      ),
    );
  }
}
