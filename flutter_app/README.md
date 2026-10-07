# Salawat — Flutter iOS/Android

This directory is the Flutter re-engineering of AndroidPrayerTimesApp.

## Architecture

- Flutter/Dart
- Cupertino-first UI for iOS
- Offline prayer-time calculation with Adhan Dart
- Offline Quran text and local Mushaf assets
- SharedPreferences local storage
- Local prayer notifications
- Optional device location
- Local Qibla calculation
- Device compass
- Arabic RTL with English fallback

The Flutter Cupertino library is designed for iOS-style interfaces, while Flutter compiles Dart ahead-of-time into the native iOS application bundle. citeturn0search0turn0search2

## Offline

No prayer-time API is required. Prayer times are calculated on-device from coordinates and the selected calculation method. Quran reading uses bundled data, so reading works without an Internet connection.

Adhan Dart provides astronomical prayer calculations for Flutter/iOS, and Geolocator provides the optional device-location fix. citeturn1search0turn1search4

## iOS build

The repository CI creates the iOS platform project and builds an unsigned IPA artifact. A signed App Store/TestFlight IPA requires Apple signing credentials. Flutter's official release flow uses Xcode and flutter build ipa. citeturn0search8

## Local commands

flutter create . --platforms=ios,android --org com.salawat_quran
flutter pub get
flutter analyze
flutter test
flutter build ipa --release

A signed IPA is emitted under build/ios/ipa when code signing is configured. citeturn0search8
