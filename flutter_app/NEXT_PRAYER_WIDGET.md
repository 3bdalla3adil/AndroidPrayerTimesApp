# Next Prayer widget

The app includes a native next-prayer widget driven by the same offline prayer calculation settings as the Prayer screen.

## iPhone Lock Screen

1. Enable **Next Prayer Widget** under Settings.
2. Long-press the iPhone Lock Screen and choose **Customize**.
3. Select the Lock Screen widget area, then add **Next Prayer** (the rectangular accessory widget).
4. The widget shows the current Hijri date, next prayer name, its local prayer time, and a live countdown.

The WidgetKit extension shares data with the Flutter app through the App Group `group.com.salawat_quran`. Before distributing a signed iOS build, register this App Group in the Apple Developer account and enable it for both the Runner app and the widget extension's provisioning profiles. Unsigned CI builds can compile the extension but cannot validate signed App Group entitlements on a physical device.

## Android

Android removed third-party lock-screen widgets from modern Android versions. The same feature is therefore provided as a native **Home screen widget**. Enable it in Settings, then long-press the Android Home screen and add **Next Prayer** from the widget picker.

## Data and refresh behavior

- Prayer times are calculated locally using the saved location, calculation method, madhab, and time adjustments.
- The app shares the next two days of prayer times with the native widget.
- The countdown is rendered by the operating system so it continues while the app is closed.
- Widget data is refreshed when the app starts, when Prayer times are loaded, and when the widget setting or prayer calculation settings change.
- iOS controls WidgetKit refresh timing; the displayed countdown itself updates live between timeline refreshes.
