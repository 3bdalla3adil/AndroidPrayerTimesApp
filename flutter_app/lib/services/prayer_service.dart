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

  Future<void> initializeTimeZone() async {
    tz_data.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  }
  CalculationParameters _parameters(int method, Coordinates coordinates) {
    final CalculationParameters params = switch (method) {
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
      //19 => CalculationMethodParameters.algeria(), // Error
      20 => CalculationMethodParameters.indonesian(),
      21 => CalculationMethodParameters.morocco(),
      23 => CalculationMethodParameters.muslimWorldLeague(),
      _ => CalculationMethodParameters.muslimWorldLeague(),
    };
    return params
      ..madhab = Madhab.shafi
      ..highLatitudeRule = HighLatitudeRule.recommended(coordinates);
  }

  Future<List<PrayerEntry>> today({bool refreshLocation = false}) async {
    await initializeTimeZone();
    var (lat, lon, _) = await storage.loadLocation();
    final selected = await storage.loadPrayerCity();
    var method = selected.$3;

    if ((lat == null || lon == null) || (refreshLocation && selected.$1 == null)) {
      final position = await determinePosition();
      lat = position.latitude;
      lon = position.longitude;
      method ??= 3;
      await storage.saveLocation(lat, lon, 'Current location');
    }
    final coordinates = Coordinates(lat, lon);
    final params = _parameters(method ?? 3, coordinates);

    final now = tz.TZDateTime.now(tz.local);
    final calculated = PrayerTimes(
      coordinates: coordinates,
      date: now,
      calculationParameters: params,
      precision: false,
    );

    DateTime localize(DateTime value) => tz.TZDateTime.from(value, tz.local);

    return [
      PrayerEntry(name: 'Fajr', arabicName: 'الفجر', time: localize(calculated.fajr)),
      PrayerEntry(name: 'Dhuhr', arabicName: 'الظهر', time: localize(calculated.dhuhr)),
      PrayerEntry(name: 'Asr', arabicName: 'العصر', time: localize(calculated.asr)),
      PrayerEntry(name: 'Maghrib', arabicName: 'المغرب', time: localize(calculated.maghrib)),
      PrayerEntry(name: 'Isha', arabicName: 'العشاء', time: localize(calculated.isha)),
    ];
  }
}
