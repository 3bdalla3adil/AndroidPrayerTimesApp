import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/prayer_city.dart';
import '../models/prayer_entry.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
/*
 info • 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre. Try replacing the use of the deprecated member with the replacement • lib/screens/prayer_screen.dart:108:23 • deprecated_member_use
   info • 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre. Try replacing the use of the deprecated member with the replacement • lib/screens/prayer_screen.dart:122:23 • deprecated_member_use
  
*/
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
  String? _country;
  String? _city;
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
      final selected = await StorageService().loadPrayerCity();
      if (!mounted) return;
      setState(() {
        _prayers = prayers;
        _location = location.$3;
        _country = selected.$1;
        _city = selected.$2;
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

  Future<void> _chooseCity() async {
    var country = _country ?? prayerCountries.first;
    var cities = citiesForCountry(country);
    var city = cities.any((item) => item.city == _city) ? _city : cities.first.city;

    final result = await showModalBottomSheet<PrayerCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            cities = citiesForCountry(country);
            if (!cities.any((item) => item.city == city)) city = cities.first.city;
            final selectedCity = cities.firstWhere((item) => item.city == city);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prayer location', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Choose a country and city. Prayer times use the city coordinates and its regional calculation method.'),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: country,
                      decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                      items: prayerCountries.map((item) => DropdownMenuItem(initialValue: item, child: Text(item))).toList(),
                      onChanged: (initialValue) {
                        if (initialValue == null) return;
                        setSheetState(() {
                          country = initialValue;
                          cities = citiesForCountry(country);
                          city = cities.first.city;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: city,
                      decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                      items: cities.map((item) => DropdownMenuItem(initialValue: item.city, child: Text(item.city))).toList(),
                      onChanged: (initialValue) => setSheetState(() => city = initialValue ?? city),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, selectedCity),
                        icon: const Icon(Icons.check),
                        label: const Text('Use this city'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;
    await StorageService().savePrayerCity(
      country: result.country,
      city: result.city,
      lat: result.latitude,
      lon: result.longitude,
      method: result.calculationMethod,
    );
    await _load();
  }

  Future<void> _useDeviceLocation() async {
    try {
      final position = await _service.determinePosition();
      await StorageService().clearPrayerCity();
      await StorageService().saveLocation(position.latitude, position.longitude, 'Current location');
      await _load();
    } catch (error) {
      if (mounted) setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _toggleReminders(bool initialValue) async {
    if (!initialValue) {
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
          Card(
            child: ListTile(
              leading: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
              title: Text(_country != null && _city != null ? '$_city, $_country' : (_location ?? 'Location not set')),
              subtitle: Text(_country == null ? 'Select a country and city' : 'Prayer calculation is based on this city'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _chooseCity,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _useDeviceLocation,
            icon: const Icon(Icons.my_location_outlined),
            label: const Text('Use my current location'),
          ),
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
                Text('Time remaining until the next prayer', style: TextStyle(color: theme.colorScheme.onInverseSurface.withValues(alpha: .7))),
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
            initialValue: _reminders,
            onChanged: _toggleReminders,
          )),
        ],
      ),
    );
  }
}
