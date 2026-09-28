import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prayer_entry.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'quran_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final service = PrayerService(StorageService());
  List<PrayerEntry> prayers = [];
  String location = 'Finding your location…';
  String? error;
  Timer? timer;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  Future<void> load({bool refresh = false}) async {
    try {
      final data = await service.today(refreshLocation: refresh);
      if (!mounted) return;
      setState(() {
        prayers = data;
        error = null;
        location = 'Current location';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  PrayerEntry? get nextPrayer {
    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) return prayer;
    }
    return null;
  }

  Duration get countdown {
    final next = nextPrayer;
    return next == null ? Duration.zero : next.time.difference(now);
  }

  String formatDuration(Duration value) {
    return value.inHours.toString().padLeft(2, '0') +
        ':' +
        (value.inMinutes % 60).toString().padLeft(2, '0') +
        ':' +
        (value.inSeconds % 60).toString().padLeft(2, '0');
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = nextPrayer;

    return RefreshIndicator(
      onRefresh: () => load(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('السلام عليكم',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(DateFormat('EEEE, d MMMM').format(now)),
                    Text(location, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => load(refresh: true),
                icon: const Icon(Icons.my_location),
                tooltip: 'Update location',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (error != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(error!),
              ),
            ),
          if (error == null && next != null)
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Text('NEXT PRAYER',
                        style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.4)),
                    const SizedBox(height: 8),
                    Text(next.arabicName,
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text(next.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(DateFormat('h:mm a').format(next.time),
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(formatDuration(countdown), style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text('Today', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...prayers.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: const Icon(Icons.access_time),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(p.arabicName, textDirection: TextDirection.rtl),
                  trailing: Text(DateFormat('h:mm a').format(p.time),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
              )),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Continue Quran reading'),
              subtitle: const Text('Pick up where you left off'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuranScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: prayers.isEmpty
                ? null
                : () async {
                    await NotificationService.cancelAll();
                    for (var i = 0; i < prayers.length; i++) {
                      await NotificationService.schedulePrayer(
                        id: 100 + i,
                        prayerName: prayers[i].name,
                        time: prayers[i].time,
                      );
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Prayer reminders scheduled.')),
                      );
                    }
                  },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Schedule prayer reminders'),
          ),
        ],
      ),
    );
  }
}
