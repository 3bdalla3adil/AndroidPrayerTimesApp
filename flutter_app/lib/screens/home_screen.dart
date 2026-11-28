import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import '../core/adaptive_controls.dart';
import '../core/adaptive_page_scaffold.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/prayer_entry.dart';
import '../services/athan_reminder_service.dart';
import '../services/tahajjud_reminder_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../services/app_routes.dart';
import '../theme/app_theme.dart';
import '../services/locale_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final _service = PrayerService(StorageService());
  late final AthanReminderService _athan;
  late final TahajjudReminderService _tahajjud;
  List<PrayerEntry> _prayers = const [];
  DateTime _now = DateTime.now();
  String _location = LocaleController.isArabic ? 'الموقع الحالي' : 'Current location';
  String? _error;
  bool _reminders = false;
  bool _tahajjudReminders = false;
  bool _tahajjudLoading = false;
  Timer? _timer;

  @override void initState() {
    super.initState();
    _athan = AthanReminderService(_service, StorageService());
    _tahajjud = TahajjudReminderService(_service, StorageService());
    _load();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Re-evaluate the next prayer once a minute. The countdown itself is
      // isolated in _NextPrayer so the whole home screen is not rebuilt
      // every second.
      if (mounted) setState(() => _now = DateTime.now());
    });
  }
  @override void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load({bool refresh = false}) async {
    try {
      final prayers = await _service.today(refreshLocation: refresh);
      final location = await StorageService().loadLocation();
      final reminders = await StorageService().loadAthanRemindersEnabled();
      final tahajjudReminders = await StorageService().loadTahajjudRemindersEnabled();
      if (!mounted) return;
      setState(() {
        _prayers = prayers; _location = location.$3 ?? (LocaleController.isArabic ? 'الموقع الحالي' : 'Current location');
        _reminders = reminders; _tahajjudReminders = tahajjudReminders; _error = null;
      });
      await _athan.sync(refreshLocation: refresh);
      await _tahajjud.sync();
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

  Future<void> _toggleTahajjud(bool enabled) async {
    if (_tahajjudLoading) return;
    setState(() => _tahajjudLoading = true);
    try {
      if (enabled) {
        final count = await _tahajjud.enable();
        if (mounted) {
          setState(() => _tahajjudReminders = true);
          _dialog(LocaleController.isArabic ? 'تم تفعيل تذكير التهجّد' : 'Tahajjud reminder enabled', LocaleController.isArabic ? 'تمت جدولة $count من التذكيرات لبداية الثلث الأخير من الليل.' : '$count reminders were scheduled for the start of the last third of the night.');
        }
      } else {
        await _tahajjud.disable();
        if (mounted) setState(() => _tahajjudReminders = false);
      }
    } catch (e) {
      if (mounted) _dialog(LocaleController.isArabic ? 'تعذّر إعداد تذكير التهجّد' : 'Could not set up Tahajjud reminder', e.toString());
    } finally {
      if (mounted) setState(() => _tahajjudLoading = false);
    }
  }

  Future<void> _continueQuran() async {
    final storage = StorageService();
    final lastPage = await storage.loadLastQuranPage();
    final markedAyah = await storage.loadLastMarkedAyah();
    if (!mounted) return;

    final surah = markedAyah.$1 ?? 1;
    final ayah = markedAyah.$2 ?? 1;
    await Navigator.of(context).pushNamed(
      AppRoutes.quranReader,
      arguments: QuranReaderRouteArgs(
        surahNumber: surah,
        startingAyah: ayah,
        startingPage: lastPage,
      ),
    );
  }

  void _dialog(String title, String message) => showAdaptiveDialog<void>(
    context: context,
    builder: (_) => AdaptiveAlertDialog(
      title: Text(title), content: Text(message),
      actions: [AdaptiveDialogAction(child: Text(LocaleController.isArabic ? 'حسنًا' : 'OK'), onPressed: () => Navigator.pop(context))],
    ),
  );

  Widget _buildMaterialHome(BuildContext context) {
    final next = _next;
    final arabic = LocaleController.isArabic;
    final colorScheme = material.Theme.of(context).colorScheme;

    Widget feature({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return material.Card(
        clipBehavior: Clip.antiAlias,
        child: material.InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: colorScheme.primary, size: 27),
                const Spacer(),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: material.Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    return AdaptivePageScaffold(
      navigationBar: material.AppBar(
        title: const Text('Salawat'),
        actions: [
          material.IconButton(
            key: const ValueKey('open-more'),
            tooltip: arabic ? 'المزيد' : 'More',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.more),
            icon: const Icon(material.Icons.more_horiz),
          ),
          material.IconButton(
            key: const ValueKey('refresh-home'),
            tooltip: arabic ? 'تحديث' : 'Refresh',
            onPressed: () => _load(refresh: true),
            icon: const Icon(material.Icons.refresh),
          ),
        ],
      ),
      child: SafeArea(
        child: material.RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              Text('السلام عليكم',
                textDirection: TextDirection.rtl,
                style: material.Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(DateFormat('EEEE, d MMMM y').format(_now)),
              Text(_location, style: material.Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 18),
              if (_error != null)
                material.Card(
                  child: material.ListTile(
                    leading: const Icon(material.Icons.warning_amber_rounded),
                    title: Text(arabic ? 'مواقيت الصلاة غير متاحة' : 'Prayer times unavailable'),
                    subtitle: Text(_error!),
                  ),
                ),
              if (next != null) _NextPrayer(prayer: next, now: _now),
              const SizedBox(height: 24),
              Text(arabic ? 'استكشف التطبيق' : 'Explore',
                style: material.Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.28,
                children: [
                  feature(icon: material.Icons.menu_book_rounded, title: arabic ? 'القرآن الكريم' : 'Quran',
                    subtitle: arabic ? 'قراءة المصحف' : 'Read Quran', onTap: _continueQuran),
                  feature(icon: material.Icons.access_time_rounded, title: arabic ? 'مواقيت الصلاة' : 'Prayer times',
                    subtitle: arabic ? 'مواعيد اليوم' : 'Today’s schedule',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.prayer)),
                  feature(icon: material.Icons.explore_rounded, title: arabic ? 'اتجاه القبلة' : 'Qibla',
                    subtitle: arabic ? 'اتجاه مكة' : 'Direction to Makkah',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.qibla)),
                  feature(icon: material.Icons.calendar_month_rounded, title: arabic ? 'التقويم الهجري' : 'Hijri calendar',
                    subtitle: arabic ? 'التاريخ والمناسبات' : 'Dates & occasions',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.calendar)),
                  feature(icon: material.Icons.auto_awesome_rounded, title: arabic ? 'التسبيح' : 'Tasbih',
                    subtitle: arabic ? 'الذكر اليومي' : 'Daily dhikr',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.tasbih)),
                  feature(icon: material.Icons.favorite_rounded, title: arabic ? 'الأذكار والأدعية' : 'Duas & Adhkar',
                    subtitle: arabic ? 'أذكار يومية' : 'Daily remembrance',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adhkar)),
                ],
              ),
              const SizedBox(height: 24),
              Text(arabic ? 'مواقيت الصلاة' : 'Prayer schedule',
                style: material.Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              material.Card(
                child: Column(
                  children: [
                    if (_prayers.isEmpty)
                      material.ListTile(
                        leading: const Icon(material.Icons.schedule_rounded),
                        title: Text(arabic ? 'مواقيت الصلاة' : 'Prayer times'),
                        subtitle: Text(arabic ? 'يرجى تحميل موقعك لحساب المواقيت' : 'Load your location to calculate today’s prayers.'),
                      )
                    else
                      for (var i = 0; i < _prayers.length; i++) ...[
                        if (i > 0) const material.Divider(height: 1),
                        material.ListTile(
                          leading: const Icon(material.Icons.access_time_rounded),
                          title: Text(_prayers[i].name),
                          subtitle: Text(_prayers[i].arabicName, textDirection: TextDirection.rtl),
                          trailing: Text(DateFormat('h:mm a').format(_prayers[i].time),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              material.Card(
                child: Column(
                  children: [
                    material.ListTile(
                      leading: const Icon(material.Icons.menu_book_rounded),
                      title: Text(arabic ? 'متابعة القراءة' : 'Continue Quran'),
                      subtitle: Text(arabic ? 'المصحف دون إنترنت' : 'Offline Mushaf'),
                      trailing: const Icon(material.Icons.chevron_right_rounded),
                      onTap: _continueQuran,
                    ),
                    const material.Divider(height: 1),
                    material.SwitchListTile(
                      secondary: const Icon(material.Icons.notifications_active_outlined),
                      title: Text(arabic ? 'تنبيهات الأذان' : 'Athan reminders'),
                      subtitle: Text(arabic ? 'تشغيل الأذان عند دخول وقت الصلاة' : 'Play Athan at each prayer time'),
                      value: _reminders,
                      onChanged: _toggle,
                    ),
                    const material.Divider(height: 1),
                    material.SwitchListTile(
                      secondary: const Icon(material.Icons.nights_stay_outlined),
                      title: Text(arabic ? 'تذكير التهجّد' : 'Tahajjud reminder'),
                      subtitle: Text(arabic ? 'تنبيه عند بداية الثلث الأخير من الليل' : 'A quiet alert at the last third of the night'),
                      value: _tahajjudReminders,
                      onChanged: _tahajjudLoading ? null : _toggleTahajjud,
                    ),
                    if (_tahajjudLoading)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: material.LinearProgressIndicator(),
                      ),
                    material.ListTile(
                      leading: const Icon(material.Icons.headphones_rounded),
                      title: Text(arabic ? 'القرّاء المتاحون' : 'Available Quran reciters'),
                      subtitle: const Text('Mishary Alafasy • Abdul Basit • Mahmoud Khalil Al-Husary'),
                      trailing: const Icon(material.Icons.chevron_right_rounded),
                      onTap: _continueQuran,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return _buildMaterialHome(context);
    }
    final next = _next;
    return AdaptivePageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Salawat'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdaptiveButton(
              key: const ValueKey('open-more'),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.more),
              child: const Icon(CupertinoIcons.ellipsis_circle),
            ),
            const SizedBox(width: 8),
            AdaptiveButton(
              key: const ValueKey('refresh-home'),
              padding: EdgeInsets.zero,
              onPressed: () => _load(refresh: true),
              child: const Icon(CupertinoIcons.refresh),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: () => _load(refresh: true)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              sliver: SliverList(delegate: SliverChildListDelegate([
                const Text('السلام عليكم', textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4), Text(DateFormat('EEEE, d MMMM y').format(_now)),
                Text(_location, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                const SizedBox(height: 18),
                if (_error != null) AdaptiveListSection.insetGrouped(children: [
                  AdaptiveListTile(leading: const Icon(CupertinoIcons.exclamationmark_triangle),
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
                  onPrayer: () => Navigator.of(context).pushNamed(AppRoutes.prayer),
                  onTasbih: () => Navigator.of(context).pushNamed(AppRoutes.tasbih),
                  onDuaa: () => Navigator.of(context).pushNamed(AppRoutes.adhkar),
                  onQibla: () => Navigator.of(context).pushNamed(AppRoutes.qibla),
                  onCalendar: () => Navigator.of(context).pushNamed(AppRoutes.calendar),
                  onAthan: () => _toggle(!_reminders),
                  onSettings: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                  remindersEnabled: _reminders,
                ),
                const SizedBox(height: 22),
                AdaptiveListSection.insetGrouped(children: [
                  if (_prayers.isEmpty) AdaptiveListTile(
                    leading: Icon(CupertinoIcons.time), title: Text(LocaleController.isArabic ? 'مواقيت الصلاة' : 'Prayer times'),
                    subtitle: Text('Load your location to calculate today\'s prayers.'),
                  ) else for (final p in _prayers) AdaptiveListTile(
                    leading: const Icon(CupertinoIcons.time), title: Text(p.name),
                    subtitle: Text(p.arabicName, textDirection: TextDirection.rtl),
                    trailing: Text(DateFormat('h:mm a').format(p.time)),
                  ),
                ]),
                AdaptiveListSection.insetGrouped(children: [
                  AdaptiveListTile(
                    leading: const Icon(CupertinoIcons.book), title: Text(LocaleController.isArabic ? 'متابعة القراءة' : 'Continue Quran'),
                    subtitle: Text(LocaleController.isArabic ? 'المصحف دون إنترنت' : 'Offline Mushaf'), trailing: const AdaptiveListTileChevron(),
                    onTap: _continueQuran,
                  ),
                  AdaptiveListTile(
                    leading: const Icon(CupertinoIcons.bell), title: Text(LocaleController.isArabic ? 'تنبيهات الأذان' : 'Athan reminders'),
                    subtitle: Text(LocaleController.isArabic ? 'تشغيل الأذان عند دخول وقت الصلاة' : 'Plays the bundled Athan at prayer time'),
                    trailing: AdaptiveButton(
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
                AdaptiveListSection.insetGrouped(children: [
                  AdaptiveListTile(
                    leading: const Icon(CupertinoIcons.moon_stars),
                    title: Text(LocaleController.isArabic ? 'تذكير التهجّد' : 'Tahajjud reminder'),
                    subtitle: Text(LocaleController.isArabic ? 'تنبيه عند بداية الثلث الأخير من الليل' : 'A quiet alert at the start of the last third of the night'),
                    trailing: _tahajjudLoading ? const AdaptiveActivityIndicator() : AdaptiveSwitch(value: _tahajjudReminders, onChanged: _toggleTahajjud),
                  ),
                  AdaptiveListTile(
                    leading: const Icon(CupertinoIcons.music_note_2),
                    title: Text(LocaleController.isArabic ? 'القرّاء المتاحون' : 'Available Quran reciters'),
                    subtitle: const Text('Mishary Alafasy • Abdul Basit • Mahmoud Khalil Al-Husary'),
                    trailing: const AdaptiveListTileChevron(),
                    onTap: _continueQuran,
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

class _NextPrayer extends StatefulWidget {
  const _NextPrayer({required this.prayer, required this.now});
  final PrayerEntry prayer;
  final DateTime now;

  @override
  State<_NextPrayer> createState() => _NextPrayerState();
}

class _NextPrayerState extends State<_NextPrayer> {
  late DateTime _now;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _now = widget.now;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void didUpdateWidget(covariant _NextPrayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _now = widget.now;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayer = widget.prayer;
    final d = prayer.time.difference(_now);
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
                    child: AdaptiveButton(
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
