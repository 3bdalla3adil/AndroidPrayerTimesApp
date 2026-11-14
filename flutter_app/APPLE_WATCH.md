# Apple Watch companion

The Apple Watch companion is intentionally glance-first. It shows only:

- Today's Hijri date.
- The next prayer name and local prayer time.
- A live hours:minutes:seconds countdown.

Prayer data is calculated by the iPhone app and transferred to the paired Watch using WatchConnectivity. Open the iPhone app and enable the existing **Next Prayer Widget** setting to populate the Watch app. Updates are sent when the iPhone refreshes its prayer schedule.

The Watch companion is a native SwiftUI watchOS app embedded in the iOS application. It does not duplicate the Quran reader, Qibla compass, prayer settings, or audio controls; those remain in the iPhone app.

## Build and install

The iOS CI job generates the Flutter iOS project, then runs:

```bash
bash tool/configure_ios_next_prayer_widget.sh
bash tool/configure_ios_watch_app.sh
```

A signed release requires the iOS app and watchOS companion to use matching Apple Developer Team signing. The unsigned CI IPA can validate compilation and packaging, but cannot be installed on a physical Watch without signing.
