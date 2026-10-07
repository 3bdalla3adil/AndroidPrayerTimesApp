import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_entry.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import 'quran_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = PrayerService(StorageService());
  List<PrayerEntry> _prayers = const [];
  DateTime _now = DateTime.now();
  String _location = 'Current location';
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prayers = await _service.today();
      final location = await StorageService().loadLocation();
      if (!mounted) return;
      setState(() {
        _prayers = prayers;
        _location = location.$3 ?? 'Current location';
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
      }
    }
  }

  PrayerEntry? get _next {
    for (final prayer in _prayers) {
      if (prayer.time.isAfter(_now)) return prayer;
    }
    return null;
  }

  Future<void> _schedule() async {
    try {
      await NotificationService.cancelAll();

      // Schedule seven days ahead so the app does not need to be opened
      // every morning. Android's boot receiver will restore these alarms
      // after a device reboot.
      final today = tz.TZDateTime.now(tz.local);
      for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
        final date = today.add(Duration(days: dayOffset));
        final prayers = await _service.forDate(date);

        for (var i = 0; i < prayers.length; i++) {
          await NotificationService.schedulePrayer(
            id: 1000 + (dayOffset * 10) + i,
            prayerName: prayers[i].name,
            time: prayers[i].time,
          );
        }
      }

      final pending = await NotificationService.pendingCount();
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Athan reminders'),
          content: Text('$pending prayer alarms are scheduled for 7 days.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Could not schedule Athan'),
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _next;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Salawat'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _load,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _load),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'السلام عليكم',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(DateFormat('EEEE, d MMMM y').format(_now)),
                  Text(_location, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                  const SizedBox(height: 18),
                  if (_error != null)
                    CupertinoListSection.insetGrouped(
                      children: [
                        CupertinoListTile(
                          leading: const Icon(CupertinoIcons.exclamationmark_triangle),
                          title: const Text('Prayer times unavailable'),
                          subtitle: Text(_error!),
                        ),
                      ],
                    ),
                  if (next != null) _NextPrayer(prayer: next, now: _now),
                  const SizedBox(height: 18),
                  const Text('Today', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  CupertinoListSection.insetGrouped(
                    children: [
                      if (_prayers.isEmpty)
                        const CupertinoListTile(
                          leading: Icon(CupertinoIcons.time),
                          title: Text('Prayer times'),
                          subtitle: Text('Load your location to calculate today\'s prayers.'),
                        )
                      else
                        for (final prayer in _prayers)
                          CupertinoListTile(
                            leading: const Icon(CupertinoIcons.time),
                            title: Text(prayer.name),
                            subtitle: Text(
                              prayer.arabicName,
                              textDirection: TextDirection.rtl,
                            ),
                            trailing: Text(
                              DateFormat('h:mm a').format(prayer.time),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.book),
                        title: const Text('Continue Quran'),
                        subtitle: const Text('Offline Mushaf'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => const QuranScreen()),
                        ),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.bell),
                        title: const Text('Athan reminders'),
                        subtitle: const Text('Schedule local prayer alerts'),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _schedule,
                          child: const Text('Enable'),
                        ),
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

class _NextPrayer extends StatelessWidget {
  const _NextPrayer({required this.prayer, required this.now});

  final PrayerEntry prayer;
  final DateTime now;

  String countdown() {
    final d = prayer.time.difference(now);
    if (d.isNegative) return '00:00:00';
    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: CupertinoColors.activeGreen.resolveFrom(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text('NEXT PRAYER', style: TextStyle(color: CupertinoColors.white, letterSpacing: 1.4)),
          const SizedBox(height: 8),
          Text(
            prayer.arabicName,
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 31, fontWeight: FontWeight.w700),
          ),
          Text(prayer.name, style: const TextStyle(color: CupertinoColors.white)),
          const SizedBox(height: 8),
          Text(DateFormat('h:mm a').format(prayer.time), style: const TextStyle(color: CupertinoColors.white, fontSize: 23, fontWeight: FontWeight.w700)),
          Text(countdown(), style: const TextStyle(color: CupertinoColors.white, fontSize: 17)),
        ],
      ),
    );
  }
}
