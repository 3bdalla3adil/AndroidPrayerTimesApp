# Salawat — Offline Android Islamic Companion

The original Android Java application has been repaired and extended without requiring a runtime API.

## Features

- Local astronomical prayer-time calculation
- Fajr, Dhuhr, Asr, Maghrib and Isha
- Offline Hijri and Gregorian calendars
- Offline Qibla compass using device sensors
- Local Athan MP3 and prayer notifications
- Prayer alarms restored after device reboot/update
- Full Quran reader with 114 surahs and 6,236 ayahs
- Quran surah search and last-reading bookmark
- Arabic RTL Quran display
- No runtime Internet permission and no HTTP/API dependency

## Offline Quran data

Quran chapter JSON files are generated during the Gradle build from the open-source Quran JSON project:

https://github.com/semarketir/quranjson

The generated files are placed under `app/src/main/assets/quran/` and become part of the APK. After the assets are generated, Quran reading itself works completely offline.

## Build

Use JDK 11 with the included Gradle wrapper:

```bash
./gradlew assembleDebug
./gradlew test
```

The first build downloads the Quran source files at build time if the local assets do not exist. This is a build-time dependency only; the installed application does not contact the Quran source or any API.

## Current default prayer location

The legacy app used Khartoum-area coordinates (15.6, 32.51) and the Egyptian calculation method. The same defaults are retained so the upgrade does not silently change existing prayer calculations.

## CI

GitHub Actions builds the debug APK and runs unit tests. The generated APK is uploaded as a workflow artifact.
