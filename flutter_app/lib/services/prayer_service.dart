import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_entry.dart';
import 'storage_service.dart';

class PrayerService {
  PrayerService(this.storage);

  final StorageService storage;

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  }

  Future<Position> determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was not granted.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  CalculationParameters _parameters(int method, Coordinates coordinates) {
    final params = switch (method) {
      1 => CalculationMethodParameters.karachi(),
      2 => CalculationMethodParameters.northAmerica(),
      3 => CalculationMethodParameters.muslimWorldLeague(),
      4 => CalculationMethodParameters.ummAlQura(),
      5 => CalculationMethodParameters.egyptian(),
      7 => CalculationMethodParameters.tehran(),
      8 => CalculationMethodParameters.gulfRegion(),
      9 => CalculationMethodParameters.kuwait(),
      10 => CalculationMethodParameters.qatar(),
      11 => CalculationMethodParameters.singapore(),
      12 => CalculationMethodParameters.france(),
      13 => CalculationMethodParameters.turkiye(),
      16 => CalculationMethodParameters.dubai(),
      17 => CalculationMethodParameters.singapore(),
      18 => CalculationMethodParameters.tunisia(),
      20 => CalculationMethodParameters.indonesian(),
      21 => CalculationMethodParameters.morocco(),
      23 => CalculationMethodParameters.muslimWorldLeague(),
      _ => CalculationMethodParameters.muslimWorldLeague(),
    };
    return params
      ..madhab = Madhab.shafi
      ..highLatitudeRule = HighLatitudeRule.recommended(coordinates);
  }

  Future<(double, double, int)> _locationAndMethod({
    bool refreshLocation = false,
  }) async {
    var (lat, lon, _) = await storage.loadLocation();
    final selected = await storage.loadPrayerCity();
    var method = selected.$3;

    if (lat == null ||
        lon == null ||
        (refreshLocation && selected.$1 == null)) {
      final position = await determinePosition();
      lat = position.latitude;
      lon = position.longitude;
      method ??= 3;
      await storage.saveLocation(lat, lon, 'Current location');
    }

    return (lat, lon, method ?? 3);
  }

  Future<List<PrayerEntry>> forDate(
    DateTime date, {
    bool refreshLocation = false,
  }) async {
    final (lat, lon, method) =
        await _locationAndMethod(refreshLocation: refreshLocation);

    final coordinates = Coordinates(lat, lon);
    final params = _parameters(method, coordinates);
    final localDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
    );

    final calculated = PrayerTimes(
      coordinates: coordinates,
      date: localDate,
      calculationParameters: params,
      precision: false,
    );

    DateTime local(DateTime value) => tz.TZDateTime.from(value, tz.local);

    return [
      PrayerEntry(name: 'Fajr', arabicName: 'الفجر', time: local(calculated.fajr)),
      PrayerEntry(name: 'Dhuhr', arabicName: 'الظهر', time: local(calculated.dhuhr)),
      PrayerEntry(name: 'Asr', arabicName: 'العصر', time: local(calculated.asr)),
      PrayerEntry(name: 'Maghrib', arabicName: 'المغرب', time: local(calculated.maghrib)),
      PrayerEntry(name: 'Isha', arabicName: 'العشاء', time: local(calculated.isha)),
    ];
  }

  Future<List<PrayerEntry>> today({bool refreshLocation = false}) {
    return forDate(
      tz.TZDateTime.now(tz.local),
      refreshLocation: refreshLocation,
    );
  }
}
