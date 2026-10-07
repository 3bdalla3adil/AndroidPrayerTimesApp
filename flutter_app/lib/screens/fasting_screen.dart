import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../services/prayer_service.dart';
import '../services/storage_service.dart';

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  final _prayerService = PrayerService(StorageService());
  List<dynamic> _prayers = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prayers = await _prayerService.today();
      if (!mounted) return;
      setState(() {
        _prayers = prayers;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  (int year, int month, int day) _hijri(DateTime date) {
    const epoch = 1948439.5;
    var y = date.year;
    var m = date.month;
    if (m <= 2) {
      y--;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4;
    final jd = (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() +
        date.day +
        b -
        1524.5;
    final days = (jd - epoch).floor();
    final hy = ((30 * days + 10646) ~/ 10631);
    final hm = ((days - _hijriToJulian(hy, 1, 1) + 1) / 29.5).floor() + 1;
    final safeMonth = hm.clamp(1, 12).toInt();
    final hd = days - _hijriToJulian(hy, safeMonth, 1) + 1;
    return (hy, safeMonth, hd);
  }

  int _hijriToJulian(int year, int month, int day) =>
      (day + (29.5 * (month - 1)).ceil() +
              (year - 1) * 354 +
              ((3 + 11 * year) / 30).floor() +
              1948439.5 -
              1)
          .floor();

  @override
  Widget build(BuildContext context) {
    final h = _hijri(DateTime.now());
    final isRamadan = h.$2 == 9;
    dynamic findPrayer(String name) {
      for (final prayer in _prayers) {
        if (prayer.name == name) return prayer;
      }
      return null;
    }
    final fajr = findPrayer('Fajr');
    final maghrib = findPrayer('Maghrib');
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Fasting'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _load,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
                children: [
                  if (_error != null)
                    CupertinoListSection.insetGrouped(
                      children: [CupertinoListTile(title: Text(_error!))],
                    ),
                  CupertinoListSection.insetGrouped(
                    header: const Text('TODAY'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.moon_fill),
                        title: Text('Hijri ${h.$3} / ${h.$2} / ${h.$1}'),
                        subtitle: Text(isRamadan ? 'Ramadan' : 'Not Ramadan'),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.sunrise),
                        title: const Text('Suhoor ends'),
                        subtitle: const Text('Fajr begins'),
                        trailing: Text(fajr == null ? '--' : DateFormat('h:mm a').format(fajr.time)),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.sunset),
                        title: const Text('Iftar'),
                        subtitle: const Text('Maghrib begins'),
                        trailing: Text(maghrib == null ? '--' : DateFormat('h:mm a').format(maghrib.time)),
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.info_circle),
                        title: Text(isRamadan ? 'Ramadan fasting guidance' : 'Fasting utilities'),
                        subtitle: const Text('Times are calculated offline from your selected prayer location. Confirm local religious calendars when needed.'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
