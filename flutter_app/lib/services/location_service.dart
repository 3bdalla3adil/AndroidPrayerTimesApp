import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Shared, foreground-only location handling for prayer times and Qibla.
///
/// Location is requested only after a user enters a feature that needs it.
/// No background location permission is required.
class LocationService {
  const LocationService();

  Future<Position> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        LocationError.serviceDisabled,
        'Location services are turned off. Enable Location in device settings and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationError.permissionPermanentlyDenied,
        'Location permission is blocked. Allow location access for this app in device settings.',
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const LocationException(
        LocationError.permissionDenied,
        'Location permission is required. Allow location access and try again.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        LocationError.serviceDisabled,
        'Location services were turned off before a position could be obtained.',
      );
    } on PermissionDeniedException {
      throw const LocationException(
        LocationError.permissionDenied,
        'Location permission was not available. Check the app permissions in device settings.',
      );
    } on TimeoutException {
      throw const LocationException(
        LocationError.timeout,
        'Could not get a fresh location in time. Move to an area with a clearer GPS signal and retry.',
      );
    }
  }

  /// Resolves a city/country when the platform geocoder is available.
  /// Prayer calculations always retain the exact GPS coordinates, even if
  /// reverse geocoding is offline or unavailable.
  Future<ResolvedLocation> resolve(Position position) async {
    try {
      final marks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 6));
      final mark = marks.isEmpty ? null : marks.first;
      final city = _firstNonEmpty([
        mark?.locality,
        mark?.subAdministrativeArea,
        mark?.administrativeArea,
        mark?.subLocality,
      ]);
      final country = _firstNonEmpty([
        mark?.country,
        mark?.isoCountryCode,
      ]);
      final code = mark?.isoCountryCode?.trim().toUpperCase();
      return ResolvedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city ?? 'Current location',
        country: country ?? 'Unknown country',
        countryCode: code,
        calculationMethod: _calculationMethodForCountry(code),
      );
    } catch (_) {
      return ResolvedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: 'Current location',
        country: 'Unknown country',
        countryCode: null,
        calculationMethod: 3,
      );
    }
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final cleaned = value?.trim();
      if (cleaned != null && cleaned.isNotEmpty) return cleaned;
    }
    return null;
  }

  /// Uses a sensible regional default; users can still choose any method in
  /// Settings. Unknown regions use Muslim World League as a safe fallback.
  int _calculationMethodForCountry(String? code) => switch (code) {
        'QA' => 10,
        'SA' => 4,
        'AE' => 16,
        'KW' => 9,
        'BH' => 4,
        'OM' => 8,
        'EG' || 'SD' || 'LB' || 'SY' => 5,
        'JO' => 23,
        'IQ' => 7,
        'TR' => 13,
        'PK' || 'BD' || 'IN' => 1,
        'US' || 'CA' => 2,
        'MY' => 17,
        'SG' => 11,
        'ID' => 20,
        'MA' => 21,
        'TN' => 18,
        'DZ' => 19,
        'FR' => 12,
        _ => 3,
      };
}

enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  timeout,
}

class LocationException implements Exception {
  const LocationException(this.reason, this.message);

  final LocationError reason;
  final String message;

  @override
  String toString() => message;
}

class ResolvedLocation {
  const ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.calculationMethod,
  });

  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String? countryCode;
  final int calculationMethod;

  String get displayName => city == 'Current location'
      ? city
      : '$city, $country';
}
