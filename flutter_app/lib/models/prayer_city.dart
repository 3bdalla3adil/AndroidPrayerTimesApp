class PrayerCity {
  const PrayerCity({
    required this.country,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.calculationMethod,
  });

  final String country;
  final String city;
  final double latitude;
  final double longitude;
  final int calculationMethod;
}

const prayerCities = <PrayerCity>[
  PrayerCity(country: 'Qatar', city: 'Doha', latitude: 25.2854, longitude: 51.5310, calculationMethod: 10),
  PrayerCity(country: 'Saudi Arabia', city: 'Riyadh', latitude: 24.7136, longitude: 46.6753, calculationMethod: 4),
  PrayerCity(country: 'Saudi Arabia', city: 'Jeddah', latitude: 21.4858, longitude: 39.1925, calculationMethod: 4),
  PrayerCity(country: 'Saudi Arabia', city: 'Makkah', latitude: 21.4225, longitude: 39.8262, calculationMethod: 4),
  PrayerCity(country: 'Saudi Arabia', city: 'Madinah', latitude: 24.5247, longitude: 39.5692, calculationMethod: 4),
  PrayerCity(country: 'United Arab Emirates', city: 'Dubai', latitude: 25.2048, longitude: 55.2708, calculationMethod: 16),
  PrayerCity(country: 'United Arab Emirates', city: 'Abu Dhabi', latitude: 24.4539, longitude: 54.3773, calculationMethod: 16),
  PrayerCity(country: 'Kuwait', city: 'Kuwait City', latitude: 29.3759, longitude: 47.9774, calculationMethod: 9),
  PrayerCity(country: 'Bahrain', city: 'Manama', latitude: 26.2235, longitude: 50.5876, calculationMethod: 4),
  PrayerCity(country: 'Oman', city: 'Muscat', latitude: 23.5880, longitude: 58.3829, calculationMethod: 8),
  PrayerCity(country: 'Egypt', city: 'Cairo', latitude: 30.0444, longitude: 31.2357, calculationMethod: 5),
  PrayerCity(country: 'Egypt', city: 'Alexandria', latitude: 31.2001, longitude: 29.9187, calculationMethod: 5),
  PrayerCity(country: 'Sudan', city: 'Khartoum', latitude: 15.5007, longitude: 32.5599, calculationMethod: 5),
  PrayerCity(country: 'Jordan', city: 'Amman', latitude: 31.9539, longitude: 35.9106, calculationMethod: 23),
  PrayerCity(country: 'Lebanon', city: 'Beirut', latitude: 33.8938, longitude: 35.5018, calculationMethod: 5),
  PrayerCity(country: 'Iraq', city: 'Baghdad', latitude: 33.3152, longitude: 44.3661, calculationMethod: 7),
  PrayerCity(country: 'Syria', city: 'Damascus', latitude: 33.5138, longitude: 36.2765, calculationMethod: 5),
  PrayerCity(country: 'Türkiye', city: 'Istanbul', latitude: 41.0082, longitude: 28.9784, calculationMethod: 13),
  PrayerCity(country: 'Pakistan', city: 'Islamabad', latitude: 33.6844, longitude: 73.0479, calculationMethod: 1),
  PrayerCity(country: 'Pakistan', city: 'Lahore', latitude: 31.5204, longitude: 74.3587, calculationMethod: 1),
  PrayerCity(country: 'Bangladesh', city: 'Dhaka', latitude: 23.8103, longitude: 90.4125, calculationMethod: 1),
  PrayerCity(country: 'India', city: 'Delhi', latitude: 28.6139, longitude: 77.2090, calculationMethod: 1),
  PrayerCity(country: 'India', city: 'Mumbai', latitude: 19.0760, longitude: 72.8777, calculationMethod: 1),
  PrayerCity(country: 'Malaysia', city: 'Kuala Lumpur', latitude: 3.1390, longitude: 101.6869, calculationMethod: 17),
  PrayerCity(country: 'Singapore', city: 'Singapore', latitude: 1.3521, longitude: 103.8198, calculationMethod: 11),
  PrayerCity(country: 'Indonesia', city: 'Jakarta', latitude: -6.2088, longitude: 106.8456, calculationMethod: 20),
  PrayerCity(country: 'Indonesia', city: 'Surabaya', latitude: -7.2575, longitude: 112.7521, calculationMethod: 20),
  PrayerCity(country: 'Morocco', city: 'Casablanca', latitude: 33.5731, longitude: -7.5898, calculationMethod: 21),
  PrayerCity(country: 'Algeria', city: 'Algiers', latitude: 36.7538, longitude: 3.0588, calculationMethod: 19),
  PrayerCity(country: 'Tunisia', city: 'Tunis', latitude: 36.8065, longitude: 10.1815, calculationMethod: 18),
  PrayerCity(country: 'United Kingdom', city: 'London', latitude: 51.5074, longitude: -0.1278, calculationMethod: 3),
  PrayerCity(country: 'France', city: 'Paris', latitude: 48.8566, longitude: 2.3522, calculationMethod: 12),
  PrayerCity(country: 'Germany', city: 'Berlin', latitude: 52.5200, longitude: 13.4050, calculationMethod: 3),
  PrayerCity(country: 'Netherlands', city: 'Amsterdam', latitude: 52.3676, longitude: 4.9041, calculationMethod: 3),
  PrayerCity(country: 'United States', city: 'New York', latitude: 40.7128, longitude: -74.0060, calculationMethod: 2),
  PrayerCity(country: 'United States', city: 'Chicago', latitude: 41.8781, longitude: -87.6298, calculationMethod: 2),
  PrayerCity(country: 'United States', city: 'Seattle', latitude: 47.6062, longitude: -122.3321, calculationMethod: 2),
  PrayerCity(country: 'Canada', city: 'Toronto', latitude: 43.6532, longitude: -79.3832, calculationMethod: 2),
  PrayerCity(country: 'Australia', city: 'Sydney', latitude: -33.8688, longitude: 151.2093, calculationMethod: 3),
  PrayerCity(country: 'New Zealand', city: 'Auckland', latitude: -36.8509, longitude: 174.7645, calculationMethod: 3),
  PrayerCity(country: 'South Africa', city: 'Johannesburg', latitude: -26.2041, longitude: 28.0473, calculationMethod: 2),
  PrayerCity(country: 'Nigeria', city: 'Lagos', latitude: 6.5244, longitude: 3.3792, calculationMethod: 3),
];

List<String> get prayerCountries {
  final values = prayerCities.map((e) => e.country).toSet().toList()..sort();
  return values;
}

List<PrayerCity> citiesForCountry(String country) =>
    prayerCities.where((e) => e.country == country).toList();
