import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/prayer_entry.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});
  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final _service = PrayerService(StorageService());
  List<PrayerEntry> _prayers = const [];
  DateTime _now = DateTime.now();
  String? _location;
  String? _message;
  bool _loading = true;
  bool _reminders = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() => _loading = true);
    try {
      final prayers = await _service.today(refreshLocation: refresh);
      final location = await StorageService().loadLocation();
      if (!mounted) return;
      setState(() {
        _prayers = prayers;
        _location = location.$3;
        _message = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  PrayerEntry? get _next {
    for (final prayer in _prayers) {
      if (prayer.time.isAfter(_now)) return prayer;
    }
    return null;
  }

  String _countdown(DateTime time) {
    final d = time.difference(_now);
    if (d.isNegative) return '00:00:00';
    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _toggleReminders(bool value) async {
    if (!value) {
      await NotificationService.cancelAll();
      if (mounted) setState(() => _reminders = false);
      return;
    }
    if (_prayers.isEmpty) {
      setState(() => _message = 'Set your location before enabling prayer reminders.');
      return;
    }
    try {
      for (var i = 0; i < _prayers.length; i++) {
        await NotificationService.schedulePrayer(id: 100 + i, prayerName: _prayers[i].name, time: _prayers[i].time);
      }
      if (mounted) setState(() { _reminders = true; _message = 'Prayer reminders scheduled.'; });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = _next;
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 110),
        children: [
          Text('YOUR DAILY RHYTHM', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.6, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
          const SizedBox(height: 7),
          Row(children: [
            Expanded(child: Text('Prayer times', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
            IconButton(onPressed: () => _load(refresh: true), icon: const Icon(Icons.refresh)),
          ]),
          Text(DateFormat('EEEE, d MMMM').format(_now), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
            title: Text(_location ?? 'Location not set'),
            subtitle: const Text('Coordinates stay on this device for local calculations.'),
          )),
          const SizedBox(height: 16),
          if (_message != null) Card(color: theme.colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(15), child: Text(_message!))),
          if (_loading) const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()))
          else if (next != null) Card(
            color: theme.colorScheme.inverseSurface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('UP NEXT', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.inversePrimary, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(next.arabicName, textDirection: TextDirection.rtl, style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.w800)),
                    Text(next.name, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onInverseSurface)),
                  ])),
                  Text(DateFormat('h:mm a').format(next.time), style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 10),
                Text(_countdown(next.time), style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onInverseSurface, fontFeatures: const [FontFeature.tabularFigures()])),
                const SizedBox(height: 4),
                Text('Time remaining until the next prayer', style: TextStyle(color: theme.colorScheme.onInverseSurface.withOpacity(.7))),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Text('Today', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ..._prayers.map((prayer) => Card(
            margin: const EdgeInsets.only(bottom: 9),
            child: ListTile(
              leading: Icon(Icons.access_time, color: theme.colorScheme.primary),
              title: Text(prayer.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(prayer.arabicName, textDirection: TextDirection.rtl),
              trailing: Text(DateFormat('h:mm a').format(prayer.time), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          )),
          Card(child: SwitchListTile(
            secondary: Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
            title: const Text('Prayer reminders'),
            subtitle: const Text('Schedule local reminders for today.'),
            value: _reminders,
            onChanged: _toggleReminders,
          )),
        ],
      ),
    );
  }
}
