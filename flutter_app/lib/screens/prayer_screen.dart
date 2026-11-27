import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import '../core/adaptive_page_scaffold.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/prayer_city.dart';
import '../models/prayer_entry.dart';
import '../services/athan_reminder_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../services/locale_controller.dart';
import '../services/next_prayer_widget_service.dart';
import '../theme/app_theme.dart';

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
      await NextPrayerWidgetService(_service, StorageService()).refresh();
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
      final resolved = await _service.determineDeviceLocation();
      final method = await StorageService().loadPrayerCalculationMethod() ??
          resolved.calculationMethod;
      await StorageService().savePrayerCity(
        country: resolved.country,
        city: resolved.city,
        lat: resolved.latitude,
        lon: resolved.longitude,
        method: method,
        isDeviceLocation: true,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _message = e.toString().replaceFirst('Bad state: ', ''));
      }
    }
  }

  Future<void> _chooseCity() async {
    final storage = StorageService();
    final saved = await storage.loadPrayerCity();
    final savedMethod = await storage.loadPrayerCalculationMethod();
    final savedLocation = await storage.loadLocation();
    final countries = <String>{
      ...prayerCountries,
      if (saved.$1 != null && saved.$1!.isNotEmpty) saved.$1!,
    }.toList()
      ..sort();

    List<PrayerCity> optionsForCountry(String selectedCountry) {
      final options = citiesForCountry(selectedCountry);
      final savedCity = saved.$2;
      if (saved.$1 == selectedCountry &&
          savedCity != null &&
          !options.any((city) => city.city == savedCity) &&
          savedLocation.$1 != null &&
          savedLocation.$2 != null) {
        options.add(PrayerCity(
          country: selectedCountry,
          city: savedCity,
          latitude: savedLocation.$1!,
          longitude: savedLocation.$2!,
          calculationMethod: saved.$3 ?? savedMethod ?? 3,
        ));
      }
      return options;
    }

    var country = saved.$1 ?? prayerCountries.first;
    var cities = optionsForCountry(country);
    var cityIndex = saved.$2 == null
        ? 0
        : cities.indexWhere((city) => city.city == saved.$2);
    if (!mounted) return;
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
                              initialItem: countries.indexOf(selectedCountry),
                            ),
                            onSelectedItemChanged: (index) {
                              final nextCountry = countries[index];
                              final nextCities = optionsForCountry(nextCountry);
                              setModalState(() {
                                selectedCountry = nextCountry;
                                selectedCities = nextCities;
                                selectedCityIndex = 0;
                              });
                            },
                            children: [
                              for (final item in countries) Center(
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

  Widget _buildMaterialPrayerTimes(BuildContext context) {
    final next = _next;
    final arabic = LocaleController.isArabic;
    return AdaptivePageScaffold(
      navigationBar: material.AppBar(
        title: Text(arabic ? 'مواقيت الصلاة' : 'Prayer times'),
        actions: [
          material.IconButton(
            tooltip: arabic ? 'تحديث' : 'Refresh',
            onPressed: () => _load(refresh: true),
            icon: const Icon(material.Icons.refresh_rounded),
          ),
        ],
      ),
      child: SafeArea(
        child: material.RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              Text(DateFormat('EEEE, d MMMM y').format(_now),
                style: material.Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              material.Card(
                child: Column(
                  children: [
                    material.ListTile(
                      leading: const Icon(material.Icons.location_on_outlined),
                      title: Text(_location),
                      subtitle: Text(arabic ? 'يُستخدم لحساب المواقيت محلياً' : 'Used locally for prayer calculations'),
                      trailing: const Icon(material.Icons.chevron_right_rounded),
                      onTap: _chooseCity,
                    ),
                    const material.Divider(height: 1),
                    material.ListTile(
                      leading: const Icon(material.Icons.my_location_rounded),
                      title: Text(arabic ? 'استخدم موقعي الحالي' : 'Use my current location'),
                      onTap: _useDeviceLocation,
                    ),
                  ],
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                material.Card(
                  child: material.ListTile(
                    leading: const Icon(material.Icons.info_outline_rounded),
                    title: Text(_message!),
                  ),
                ),
              ],
              if (next != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.emerald, AppTheme.deepEmerald],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusHero),
                    border: Border.all(color: AppTheme.antiqueGold.withValues(alpha: .5)),
                  ),
                  child: Column(
                    children: [
                      Text(arabic ? 'الصلاة القادمة' : 'UP NEXT',
                        style: const TextStyle(color: AppTheme.goldHighlight, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text(next.arabicName, textDirection: TextDirection.rtl,
                        style: const TextStyle(color: AppTheme.warmIvory, fontSize: 28, fontWeight: FontWeight.w700)),
                      Text(next.name, style: const TextStyle(color: AppTheme.warmIvory)),
                      const SizedBox(height: 6),
                      Text(DateFormat('h:mm a').format(next.time),
                        style: const TextStyle(color: AppTheme.warmIvory, fontSize: 23, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(arabic ? 'مواقيت اليوم' : 'Today’s schedule',
                style: material.Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              material.Card(
                child: Column(
                  children: [
                    if (_prayers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(arabic ? 'لم يتم تحميل المواقيت بعد' : 'Prayer times have not loaded yet'),
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
              const SizedBox(height: 12),
              material.Card(
                child: material.SwitchListTile(
                  secondary: const Icon(material.Icons.notifications_active_outlined),
                  title: Text(arabic ? 'تنبيهات الأذان' : 'Athan reminders'),
                  subtitle: Text(arabic ? 'تشغيل الأذان عند دخول وقت كل صلاة' : 'Play the bundled Athan at each prayer time'),
                  value: _reminders,
                  onChanged: _toggleReminders,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return _buildMaterialPrayerTimes(context);
    }
    final next = _next;

    return AdaptivePageScaffold(
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
                  title: Text(LocaleController.isArabic ? 'استخدم موقعي الحالي' : 'Use my current location'),
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
                  color: AppTheme.emerald,
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
              header: Text(LocaleController.isArabic ? 'اليوم' : 'TODAY'),
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
                  title: Text(LocaleController.isArabic ? 'تنبيهات الأذان' : 'Athan reminders'),
                  subtitle: Text(LocaleController.isArabic ? 'تشغيل الأذان عند دخول وقت كل صلاة' : 'Plays the bundled Athan at each prayer time'),
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
