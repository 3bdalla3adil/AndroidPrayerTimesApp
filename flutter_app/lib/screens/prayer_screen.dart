import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/prayer_city.dart';
import '../models/prayer_entry.dart';
import '../services/athan_reminder_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final _service = PrayerService(StorageService());
  late final AthanReminderService _athan;
  List<PrayerEntry> _prayers = const [];
  DateTime _now = DateTime.now();
  String _location = 'Location not set';
  String? _message;
  bool _reminders = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _athan = AthanReminderService(_service, StorageService());
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

  Future<void> _load({bool refresh = false}) async {
    try {
      final prayers = await _service.today(refreshLocation: refresh);
      final location = await StorageService().loadLocation();
      final reminders = await StorageService().loadAthanRemindersEnabled();
      if (!mounted) return;
      setState(() {
        _prayers = prayers;
        _location = location.$3 ?? 'Current location';
        _reminders = reminders;
        _message = null;
      });
      await _athan.sync(refreshLocation: refresh);
    } catch (e) {
      if (mounted) {
        setState(() => _message = e.toString().replaceFirst('Bad state: ', ''));
      }
    }
  }

  PrayerEntry? get _next {
    for (final p in _prayers) {
      if (p.time.isAfter(_now)) return p;
    }
    return null;
  }

  Future<void> _useDeviceLocation() async {
    try {
      final position = await _service.determinePosition();
      await StorageService().clearPrayerCity();
      await StorageService().saveLocation(
        position.latitude,
        position.longitude,
        'Current location',
      );
      await _load();
    } catch (e) {
      if (mounted) setState(() => _message = e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _chooseCity() async {
    final saved = await StorageService().loadPrayerCity();
    var country = saved.$1 ?? prayerCountries.first;
    var cities = citiesForCountry(country);
    var cityIndex = saved.$2 == null
        ? 0
        : cities.indexWhere((city) => city.city == saved.$2);
    if (cityIndex < 0) cityIndex = 0;

    final result = await showCupertinoModalPopup<PrayerCity>(
      context: context,
      builder: (popupContext) {
        var selectedCountry = country;
        var selectedCities = cities;
        var selectedCityIndex = cityIndex;

        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: 430,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(popupContext),
                      ),
                      const Text(
                        'Prayer location',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      CupertinoButton(
                        child: const Text('Done'),
                        onPressed: () => Navigator.pop(
                          popupContext,
                          selectedCities[selectedCityIndex],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 44,
                            scrollController: FixedExtentScrollController(
                              initialItem: prayerCountries.indexOf(selectedCountry),
                            ),
                            onSelectedItemChanged: (index) {
                              final nextCountry = prayerCountries[index];
                              final nextCities = citiesForCountry(nextCountry);
                              setModalState(() {
                                selectedCountry = nextCountry;
                                selectedCities = nextCities;
                                selectedCityIndex = 0;
                              });
                            },
                            children: [
                              for (final item in prayerCountries) Center(
                                child: Text(item),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 44,
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedCityIndex,
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() => selectedCityIndex = index);
                            },
                            children: [
                              for (final city in selectedCities) Center(
                                child: Text(city.city),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  Future<void> _toggleReminders(bool enabled) async {
    try {
      if (enabled) {
        await _athan.enable();
        if (mounted) setState(() => _reminders = true);
      } else {
        await _athan.disable();
        if (mounted) setState(() => _reminders = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = e.toString().replaceFirst('Bad state: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _next;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Prayer times'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _load(refresh: true),
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
          children: [
            Text(DateFormat('EEEE, d MMMM y').format(_now)),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.location),
                  title: Text(_location),
                  subtitle: const Text('Used locally for calculation'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _chooseCity,
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.location_fill),
                  title: const Text('Use my current location'),
                  onTap: _useDeviceLocation,
                ),
              ],
            ),
            if (_message != null)
              CupertinoListSection.insetGrouped(
                children: [CupertinoListTile(title: Text(_message!))],
              ),
            if (next != null)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeGreen.resolveFrom(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('UP NEXT', style: TextStyle(color: CupertinoColors.white)),
                    Text(next.arabicName, textDirection: TextDirection.rtl, style: const TextStyle(color: CupertinoColors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                    Text(DateFormat('h:mm a').format(next.time), style: const TextStyle(color: CupertinoColors.white, fontSize: 22)),
                  ],
                ),
              ),
            CupertinoListSection.insetGrouped(
              header: const Text('TODAY'),
              children: [
                for (final prayer in _prayers)
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.time),
                    title: Text(prayer.name),
                    subtitle: Text(prayer.arabicName, textDirection: TextDirection.rtl),
                    trailing: Text(DateFormat('h:mm a').format(prayer.time)),
                  ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.bell),
                  title: const Text('Athan reminders'),
                  subtitle: const Text('Plays the bundled Athan at each prayer time'),
                  trailing: CupertinoSwitch(
                    value: _reminders,
                    onChanged: _toggleReminders,
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
