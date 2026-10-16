import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/prayer_entry.dart';
import '../services/athan_reminder_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../services/app_routes.dart';
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
  String _location = LocaleController.isArabic ? 'الموقع الحالي' : 'Current location';
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
        _prayers = prayers; _location = location.$3 ?? (LocaleController.isArabic ? 'الموقع الحالي' : 'Current location');
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
        if (mounted) { setState(() => _reminders = true); _dialog(LocaleController.isArabic ? 'تم تفعيل الأذان' : 'Athan enabled', LocaleController.isArabic ? 'تمت جدولة $count من تنبيهات الصلاة.' : '$count prayer notifications scheduled.'); }
      } else {
        await _athan.disable();
        if (mounted) setState(() => _reminders = false);
      }
    } catch (e) { if (mounted) _dialog(LocaleController.isArabic ? 'تعذّر إعداد الأذان' : 'Athan setup failed', e.toString()); }
  }

  void _continueQuran() {
    // Open the single Quran tab. Never restore or persist the last-read page.
    RootTabNavigation.maybeOf(context)?.selectTab(1);
  }

  void _dialog(String title, String message) => showCupertinoDialog<void>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title), content: Text(message),
      actions: [CupertinoDialogAction(child: Text(LocaleController.isArabic ? 'حسنًا' : 'OK'), onPressed: () => Navigator.pop(context))],
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
                    title: Text(LocaleController.isArabic ? 'مواقيت الصلاة غير متاحة' : 'Prayer times unavailable'), subtitle: Text(_error!)),
                ]),
                if (next != null) _NextPrayer(prayer: next, now: _now),
                const SizedBox(height: 22),
                Text(
                  LocaleController.isArabic ? 'استكشف التطبيق' : 'Explore',
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _HomeFeatureGrid(
                  onQuran: _continueQuran,
                  onPrayer: () => RootTabNavigation.maybeOf(context)?.selectTab(2),
                  onTasbih: () => Navigator.of(context).pushNamed(AppRoutes.tasbih),
                  onDuaa: () => Navigator.of(context).pushNamed(AppRoutes.adhkar),
                  onQibla: () => RootTabNavigation.maybeOf(context)?.selectTab(3),
                  onCalendar: () => Navigator.of(context).pushNamed(AppRoutes.calendar),
                  onAthan: () => _toggle(!_reminders),
                  onSettings: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                  remindersEnabled: _reminders,
                ),
                const SizedBox(height: 22),
                CupertinoListSection.insetGrouped(children: [
                  if (_prayers.isEmpty) CupertinoListTile(
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
                    leading: const Icon(CupertinoIcons.book), title: Text(LocaleController.isArabic ? 'متابعة القراءة' : 'Continue Quran'),
                    subtitle: Text(LocaleController.isArabic ? 'المصحف دون إنترنت' : 'Offline Mushaf'), trailing: const CupertinoListTileChevron(),
                    onTap: _continueQuran,
                  ),
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.bell), title: Text(LocaleController.isArabic ? 'تنبيهات الأذان' : 'Athan reminders'),
                    subtitle: Text(LocaleController.isArabic ? 'تشغيل الأذان عند دخول وقت الصلاة' : 'Plays the bundled Athan at prayer time'),
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
        Text(LocaleController.isArabic ? 'الصلاة القادمة' : 'NEXT PRAYER', style: const TextStyle(color: CupertinoColors.white, letterSpacing: 1.4)),
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
    required this.onCalendar,
    required this.onAthan,
    required this.onSettings,
    required this.remindersEnabled,
  });

  final VoidCallback onQuran;
  final VoidCallback onPrayer;
  final VoidCallback onTasbih;
  final VoidCallback onDuaa;
  final VoidCallback onQibla;
  final VoidCallback onCalendar;
  final VoidCallback onAthan;
  final VoidCallback onSettings;
  final bool remindersEnabled;

  @override
  Widget build(BuildContext context) {
    final arabic = LocaleController.isArabic;
    final reading = <(String, String, IconData, VoidCallback)>[
      (arabic ? 'القرآن الكريم' : 'Quran', arabic ? 'قراءة المصحف' : 'Read Quran', CupertinoIcons.book_fill, onQuran),
      (arabic ? 'التسبيح' : 'Tasbih', arabic ? 'الذكر اليومي' : 'Daily dhikr', CupertinoIcons.circle_grid_3x3_fill, onTasbih),
      (arabic ? 'الأذكار والأدعية' : 'Duas & Adhkar', arabic ? 'أذكار يومية' : 'Daily remembrance', CupertinoIcons.heart_fill, onDuaa),
    ];
    final prayer = <(String, String, IconData, VoidCallback)>[
      (arabic ? 'مواقيت الصلاة' : 'Prayer times', arabic ? 'مواعيد اليوم' : 'Today’s schedule', CupertinoIcons.time, onPrayer),
      (arabic ? 'اتجاه القبلة' : 'Qibla', arabic ? 'اتجاه مكة' : 'Direction to Makkah', CupertinoIcons.compass_fill, onQibla),
      (arabic ? 'التقويم الهجري' : 'Hijri calendar', arabic ? 'التاريخ والمناسبات' : 'Dates & occasions', CupertinoIcons.calendar, onCalendar),
    ];
    final tools = <(String, String, IconData, VoidCallback)>[
      (arabic ? 'تنبيهات الأذان' : 'Athan alerts', remindersEnabled ? (arabic ? 'مفعّلة' : 'Enabled') : (arabic ? 'غير مفعّلة' : 'Disabled'), remindersEnabled ? CupertinoIcons.bell_fill : CupertinoIcons.bell, onAthan),
      (arabic ? 'إعدادات التطبيق' : 'App settings', arabic ? 'اللغة والمظهر' : 'Language & appearance', CupertinoIcons.gear, onSettings),
    ];

    Widget row(String title, List<(String, String, IconData, VoidCallback)> items) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.secondaryLabel)),
            ),
            SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 2),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return SizedBox(
                    width: 148,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: item.$4,
                      child: Container(
                        width: double.infinity,
                        height: 122,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: .45)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(item.$3, size: 25, color: AppTheme.emerald),
                            const Spacer(),
                            Text(
                              item.$1,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        row(arabic ? 'القرآن والذكر' : 'Quran & remembrance', reading),
        row(arabic ? 'الصلاة والقبلة' : 'Prayer & direction', prayer),
        row(arabic ? 'التنبيهات والتخصيص' : 'Alerts & preferences', tools),
      ],
    );
  }
}
