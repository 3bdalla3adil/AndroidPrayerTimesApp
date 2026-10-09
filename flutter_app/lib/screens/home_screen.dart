import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/prayer_entry.dart';
import '../services/athan_reminder_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import 'quran_reader_screen.dart';
import 'adhkar_screen.dart';
import 'tasbih_screen.dart';
import '../theme/app_theme.dart';
import '../services/locale_controller.dart';
import '../services/root_tab_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final _service = PrayerService(StorageService());
  late final AthanReminderService _athan;
  List<PrayerEntry> _prayers = const [];
  DateTime _now = DateTime.now();
  String _location = 'Current location';
  String? _error;
  bool _reminders = false;
  Timer? _timer;

  @override void initState() {
    super.initState();
    _athan = AthanReminderService(_service, StorageService());
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }
  @override void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load({bool refresh = false}) async {
    try {
      final prayers = await _service.today(refreshLocation: refresh);
      final location = await StorageService().loadLocation();
      final reminders = await StorageService().loadAthanRemindersEnabled();
      if (!mounted) return;
      setState(() {
        _prayers = prayers; _location = location.$3 ?? 'Current location';
        _reminders = reminders; _error = null;
      });
      await _athan.sync(refreshLocation: refresh);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  PrayerEntry? get _next {
    for (final p in _prayers) { if (p.time.isAfter(_now)) return p; }
    return null;
  }

  Future<void> _toggle(bool enabled) async {
    try {
      if (enabled) {
        final count = await _athan.enable();
        if (mounted) { setState(() => _reminders = true); _dialog('Athan enabled', '$count prayer notifications scheduled.'); }
      } else {
        await _athan.disable();
        if (mounted) setState(() => _reminders = false);
      }
    } catch (e) { if (mounted) _dialog('Athan setup failed', e.toString()); }
  }

  Future<void> _continueQuran() async {
    final storage = StorageService();
    final (surah, ayah) = await storage.loadReaderPosition();
    final page = await storage.loadReaderPage();
    if (!mounted) return;
    if (surah == null) {
      // No saved reading position yet: use the Quran's main tab instead of
      // creating a second copy of the surah-selection screen on the Home stack.
      RootTabNavigation.maybeOf(context)?.selectTab(1);
      return;
    }
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => QuranReaderScreen(
          surahNumber: surah,
          startingAyah: ayah ?? 1,
          startingPage: page,
        ),
      ),
    );
  }

  void _dialog(String title, String message) => showCupertinoDialog<void>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title), content: Text(message),
      actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
    ),
  );

  @override Widget build(BuildContext context) {
    final next = _next;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Salawat'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero, onPressed: () => _load(refresh: true),
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: () => _load(refresh: true)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
              sliver: SliverList(delegate: SliverChildListDelegate([
                const Text('السلام عليكم', textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4), Text(DateFormat('EEEE, d MMMM y').format(_now)),
                Text(_location, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                const SizedBox(height: 18),
                if (_error != null) CupertinoListSection.insetGrouped(children: [
                  CupertinoListTile(leading: const Icon(CupertinoIcons.exclamationmark_triangle),
                    title: const Text(LocaleController.isArabic ? 'مواقيت الصلاة غير متاحة' : 'Prayer times unavailable'), subtitle: Text(_error!)),
                ]),
                if (next != null) _NextPrayer(prayer: next, now: _now),
                const SizedBox(height: 18),
                const Text('Today', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  'Quick access',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _HomeFeatureGrid(
                  onQuran: _continueQuran,
                  onPrayer: () {
                    RootTabNavigation.maybeOf(context)?.selectTab(2);
                  },
                  onTasbih: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const TasbihScreen()),
                  ),
                  onDuaa: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const AdhkarScreen()),
                  ),
                  onQibla: () {
                    RootTabNavigation.maybeOf(context)?.selectTab(3);
                  },
                ),
                const SizedBox(height: 18),
                CupertinoListSection.insetGrouped(children: [
                  if (_prayers.isEmpty) const CupertinoListTile(
                    leading: Icon(CupertinoIcons.time), title: Text(LocaleController.isArabic ? 'مواقيت الصلاة' : 'Prayer times'),
                    subtitle: Text('Load your location to calculate today\'s prayers.'),
                  ) else for (final p in _prayers) CupertinoListTile(
                    leading: const Icon(CupertinoIcons.time), title: Text(p.name),
                    subtitle: Text(p.arabicName, textDirection: TextDirection.rtl),
                    trailing: Text(DateFormat('h:mm a').format(p.time)),
                  ),
                ]),
                CupertinoListSection.insetGrouped(children: [
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.book), title: const Text(LocaleController.isArabic ? 'متابعة القراءة' : 'Continue Quran'),
                    subtitle: const Text(LocaleController.isArabic ? 'المصحف دون إنترنت' : 'Offline Mushaf'), trailing: const CupertinoListTileChevron(),
                    onTap: _continueQuran,
                  ),
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.bell), title: const Text(LocaleController.isArabic ? 'تنبيهات الأذان' : 'Athan reminders'),
                    subtitle: const Text(LocaleController.isArabic ? 'تشغيل الأذان عند دخول وقت الصلاة' : 'Plays the bundled Athan at prayer time'),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(36, 36),
                      onPressed: () => _toggle(!_reminders),
                      child: Icon(
                        _reminders ? CupertinoIcons.bell_fill : CupertinoIcons.bell_slash,
                        size: 25,
                      ),
                    ),
                  ),
                ]),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextPrayer extends StatelessWidget {
  const _NextPrayer({required this.prayer, required this.now});
  final PrayerEntry prayer; final DateTime now;
  @override Widget build(BuildContext context) {
    final d = prayer.time.difference(now);
    final c = d.isNegative ? '00:00:00' :
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes%60).toString().padLeft(2,'0')}:${(d.inSeconds%60).toString().padLeft(2,'0')}';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.emerald, AppTheme.deepEmerald],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.antiqueGold.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(color: AppTheme.deepEmerald.withValues(alpha: .18), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(children: [
        const Text('NEXT PRAYER', style: TextStyle(color: CupertinoColors.white, letterSpacing: 1.4)),
        const SizedBox(height: 8),
        Text(prayer.arabicName, textDirection: TextDirection.rtl,
          style: const TextStyle(color: CupertinoColors.white, fontSize: 31, fontWeight: FontWeight.w700)),
        Text(prayer.name, style: const TextStyle(color: CupertinoColors.white)),
        const SizedBox(height: 8),
        Text(DateFormat('h:mm a').format(prayer.time), style: const TextStyle(color: CupertinoColors.white, fontSize: 23, fontWeight: FontWeight.w700)),
        Text(c, style: const TextStyle(color: CupertinoColors.white, fontSize: 17)),
      ]),
    );
  }
}


class _HomeFeatureGrid extends StatelessWidget {
  const _HomeFeatureGrid({
    required this.onQuran,
    required this.onPrayer,
    required this.onTasbih,
    required this.onDuaa,
    required this.onQibla,
  });

  final VoidCallback onQuran;
  final VoidCallback onPrayer;
  final VoidCallback onTasbih;
  final VoidCallback onDuaa;
  final VoidCallback onQibla;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('القرآن الكريم', 'Quran', CupertinoIcons.book_fill, onQuran),
      ('أوقات الصلاة', 'Prayer', CupertinoIcons.time_solid, onPrayer),
      ('التسبيح', 'Tasbih', CupertinoIcons.circle_grid_3x3_fill, onTasbih),
      ('الدعاء والأذكار', 'Duaa', CupertinoIcons.heart_fill, onDuaa),
      ('القبلة', 'Qibla', CupertinoIcons.compass_fill, onQibla),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final spacing = columns == 3 ? 12.0 : 10.0;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: item.$4,
                  child: Container(
                    height: 132,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.emerald.withValues(alpha: .18)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepEmerald.withValues(alpha: .06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.$3, size: 31, color: AppTheme.emerald),
                        const SizedBox(height: 8),
                        Text(
                          item.$1,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
