import 'package:flutter/cupertino.dart';
import 'package:quran/quran.dart' as quran;

import '../core/adaptive_page_scaffold.dart';
import '../services/app_routes.dart';
import '../services/daily_wird_service.dart';
import '../services/locale_controller.dart';

class DailyWirdScreen extends StatefulWidget {
  const DailyWirdScreen({super.key});
  @override
  State<DailyWirdScreen> createState() => _DailyWirdScreenState();
}

class _DailyWirdScreenState extends State<DailyWirdScreen> {
  final _service = DailyWirdService();
  DailyWirdPlan? _plan;
  bool _loading = true;
  bool get _ar => LocaleController.isArabic;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final plan = await _service.loadToday();
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _loading = false;
    });
  }

  String _position(WirdPosition p) =>
      '${quran.getSurahNameArabic(p.surah)} • ${_ar ? 'الآية' : 'Ayah'} ${p.ayah} • ${_ar ? 'صفحة' : 'Page'} ${quran.getPageNumber(p.surah, p.ayah)}';

  Future<void> _startReading() async {
    final plan = _plan;
    if (plan == null) return;
    await Navigator.of(context).pushNamed(
      AppRoutes.quranReader,
      arguments: QuranReaderRouteArgs(
        surahNumber: plan.start.surah,
        startingAyah: plan.start.ayah,
        startingPage: quran.getPageNumber(plan.start.surah, plan.start.ayah),
      ),
    );
    await _refresh();
  }

  Future<void> _confirm() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(_ar ? 'إتمام الورد اليومي' : 'Complete today’s wird?'),
        content: Text(_ar
            ? 'هل أتممت قراءة الورد المحدد لهذا اليوم؟ سيُحفظ موضع البداية التالي تلقائياً.'
            : 'Have you finished today’s reading? Your next starting point will be saved.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_ar ? 'ليس بعد' : 'Not yet'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_ar ? 'نعم، أتممت' : 'Yes, completed'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.confirmCompletion();
    await _refresh();
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(_ar ? 'تقبّل الله منك' : 'Well done'),
        content: Text(_ar
            ? 'تم تسجيل إنجاز ورد اليوم وحفظ نقطة البداية للورد القادم.'
            : 'Today’s wird has been recorded and your next reading point is saved.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_ar ? 'حسنًا' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return AdaptivePageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_ar ? 'الورد اليومي' : 'Daily Wird'),
      ),
      child: SafeArea(
        child: _loading || plan == null
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF104B3D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_ar ? 'وردك لهذا اليوم' : 'YOUR DAILY READING',
                            style: const TextStyle(color: Color(0xFFD7C18A), fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text('${plan.amount} ${_unitLabel(plan.unit)}',
                            style: const TextStyle(color: CupertinoColors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_position(plan.start), style: const TextStyle(color: CupertinoColors.white, height: 1.5)),
                        Text('${_ar ? 'إلى' : 'To'}: ${_position(plan.end)}',
                            style: const TextStyle(color: CupertinoColors.white, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_ar ? 'التقدم' : 'Progress', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(plan.completed ? (_ar ? 'مكتمل ✓' : 'Completed ✓') : '${plan.completedAyahs} / ${plan.totalAyahs} ${_ar ? 'آية' : 'ayahs'}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: plan.completed ? 1 : plan.fraction,
                      backgroundColor: CupertinoColors.systemGrey5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    plan.completed
                        ? (_ar ? 'أحسنت! أتممت ورد اليوم.' : 'You have completed today’s wird.')
                        : (_ar ? 'يُحفظ تقدم القراءة تلقائياً أثناء التنقل بين صفحات المصحف. أكّد الإتمام بعد الفراغ.' : 'Progress is saved as you move through Mushaf pages. Confirm when finished.'),
                    style: const TextStyle(color: CupertinoColors.secondaryLabel, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  CupertinoButton.filled(
                    onPressed: plan.completed ? null : _startReading,
                    child: Text(_ar ? 'ابدأ القراءة من موضع الورد' : 'Start reading'),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    onPressed: plan.completed ? null : _confirm,
                    child: Text(_ar ? 'أتممت الورد اليوم' : 'I finished today’s wird'),
                  ),
                  if (plan.completed) ...[
                    const SizedBox(height: 12),
                    Text(
                      _ar
                          ? 'موضع الورد القادم: ${_position(_nextStart(plan.end))}'
                          : 'Next reading starts at: ${_position(_nextStart(plan.end))}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: CupertinoColors.secondaryLabel),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  WirdPosition _nextStart(WirdPosition end) {
    if (end.surah == 114 && end.ayah == 6) return const WirdPosition(1, 1);
    if (end.ayah < quran.getVerseCount(end.surah)) return WirdPosition(end.surah, end.ayah + 1);
    return end.surah < 114 ? WirdPosition(end.surah + 1, 1) : const WirdPosition(1, 1);
  }

  String _unitLabel(WirdUnit unit) {
    switch (unit) {
      case WirdUnit.juz:
        return _ar ? 'جزء يومياً' : 'Juz per day';
      case WirdUnit.hizb:
        return _ar ? 'حزب يومياً' : 'Hizb per day';
      case WirdUnit.ayah:
        return _ar ? 'آية يومياً' : 'ayahs per day';
    }
  }
}
