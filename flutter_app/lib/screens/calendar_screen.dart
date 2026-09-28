import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;   // ← the fix

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  int hijriApprox(DateTime date) {
    final jd = (date.millisecondsSinceEpoch / 86400000) + 2440587.5;
    return ((jd - 1948439.5) / 29.530588).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(DateFormat('EEEE, d MMMM y').format(now),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('Gregorian calendar'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'التاريخ الهجري',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text('Approximate Hijri cycle ${hijriApprox(now)}'),
                  const SizedBox(height: 12),
                  const Text(
                    'Hijri dates can differ by local moon-sighting and official calendars.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
