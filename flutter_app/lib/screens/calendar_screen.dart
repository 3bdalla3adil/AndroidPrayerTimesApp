import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:hijri_core/hijri_core.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _islamicEpoch = 1948439.5;
  static const _hijriMonths = <String>[
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Shaaban',
    'Ramadan', 'Shawwal', 'Dhul-Qidah', 'Dhul-Hijjah',
  ];

  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  (int year, int month, int day) _hijri(DateTime date) {
    final converted = toHijri(DateTime.utc(date.year, date.month, date.day));
    if (converted == null) {
      throw StateError('Unable to convert Gregorian date to Hijri.');
    }
    return (converted.hy, converted.hm, converted.hd);
  }

  String _arabic(int value) {
    const western = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    return value
        .toString()
        .split('')
        .map((c) => arabic[western.indexOf(c)])
        .join();
  }

  void _moveMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentHijri = _hijri(now);
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final offset = first.weekday % 7;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Calendar'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _goToToday,
          child: const Text('Today'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 40),
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('TODAY'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.calendar_today),
                  title: Text(DateFormat('EEEE, d MMMM y').format(now)),
                  subtitle: Text(
                    '${_arabic(currentHijri.$3)} / '
                    '${_arabic(currentHijri.$2)} / '
                    '${_arabic(currentHijri.$1)} هـ • '
                    '${_hijriMonths[currentHijri.$2 - 1]}',
                    textDirection: ui.TextDirection.rtl,
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('MONTH'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _moveMonth(-1),
                        child: const Icon(CupertinoIcons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat('MMMM y').format(_visibleMonth),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _moveMonth(1),
                        child: const Icon(CupertinoIcons.chevron_right),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          _Weekday('Sun'), _Weekday('Mon'), _Weekday('Tue'),
                          _Weekday('Wed'), _Weekday('Thu'), _Weekday('Fri'),
                          _Weekday('Sat'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 42,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: .86,
                        ),
                        itemBuilder: (context, index) {
                          final day = index - offset + 1;
                          final date = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month,
                            day,
                          );
                          final inMonth = date.month == _visibleMonth.month;
                          if (!inMonth) return const SizedBox.shrink();
                          final h = _hijri(date);
                          final isToday = date == today;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: isToday
                                  ? CupertinoColors.activeBlue.withValues(alpha: .14)
                                  : null,
                              border: Border.all(
                                color: isToday
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.separator,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    date.day.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _arabic(h.$3),
                                    textDirection: ui.TextDirection.rtl,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.moon),
                  title: Text(
                    '${_hijri(_visibleMonth).$1} / '
                    '${_hijri(_visibleMonth).$2} • '
                    '${_hijriMonths[_hijri(_visibleMonth).$2 - 1]}',
                  ),
                  subtitle: const Text(
                    'Each day shows its calculated Hijri day alongside the Gregorian date.',
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('CALENDAR ACCURACY'),
              children: [
                CupertinoListTile(
                  leading: Icon(CupertinoIcons.info),
                  title: Text('Calculated Hijri calendar'),
                  subtitle: Text(
                    'This offline civil calculation can differ from an official or moon-sighting calendar by one day.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
