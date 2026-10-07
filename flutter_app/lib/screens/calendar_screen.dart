import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});
  static const _islamicEpoch = 1948439.5;

  (int year, int month, int day) hijri(DateTime date) {
    final jd = _gregorianToJulian(date.year, date.month, date.day);
    final days = (jd - _islamicEpoch).floor();
    final year = ((30 * days + 10646) ~/ 10631);
    final month = ((days - _islamicToJulian(year, 1, 1) + 1) / 29.5).floor() + 1;
    final safeMonth = month.clamp(1, 12);
    final dayOfMonth = days - _islamicToJulian(year, safeMonth, 1) + 1;
    return (year, safeMonth, dayOfMonth);
  }

  double _gregorianToJulian(int year, int month, int day) {
    var y = year, m = month;
    if (m <= 2) { y--; m += 12; }
    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4;
    return (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() + day + b - 1524.5;
  }

  int _islamicToJulian(int year, int month, int day) =>
      (day + (29.5 * (month - 1)).ceil() + (year - 1) * 354 +
              ((3 + 11 * year) / 30).floor() + _islamicEpoch - 1)
          .floor();

  String _arabic(int value) {
    const western = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    return value.toString().split('').map((c) => arabic[western.indexOf(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final h = hijri(now);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Calendar')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 40),
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('GREGORIAN'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.calendar),
                  title: Text(DateFormat('EEEE, d MMMM y').format(now)),
                  subtitle: const Text('Today'),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('HIJRI'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.moon),
                  title: Text(
                    _arabic(h.$3) + ' / ' + _arabic(h.$2) + ' / ' + _arabic(h.$1),
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: const Text('Offline tabular Hijri date'),
                ),
                const CupertinoListTile(
                  leading: Icon(CupertinoIcons.info),
                  title: Text('Moon sighting'),
                  subtitle: Text('The civil calculation may differ from local or official calendars by one day.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
