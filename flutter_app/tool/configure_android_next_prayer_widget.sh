#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

PACKAGE_DIR="android/app/src/main/kotlin/com/salawat_quran/salawat_quran"
mkdir -p "$PACKAGE_DIR" android/app/src/main/res/layout android/app/src/main/res/xml
cat > "$PACKAGE_DIR/NextPrayerWidgetProvider.kt" <<'KOTLIN'
package com.salawat_quran.salawat_quran

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.time.Instant
import java.time.chrono.HijrahChronology
import java.time.format.DateTimeFormatter
import java.util.Locale

class NextPrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val data = HomeWidgetPlugin.getData(context)
        val enabled = data.getBoolean("widget_enabled", false)
        val locale = if (data.getString("widget_locale", "ar") == "ar") Locale("ar") else Locale.US
        val now = System.currentTimeMillis()
        val hijriFormatter = DateTimeFormatter.ofPattern("d MMMM yyyy", locale)
            .withChronology(HijrahChronology.INSTANCE)
        val hijriDate = hijriFormatter.format(Instant.ofEpochMilli(now).atZone(java.time.ZoneId.systemDefault()))

        var nextName = if (locale.language == "ar") "الفجر" else "Fajr"
        var nextTime = "--:--"
        var nextAt = 0L
        val raw = data.getString("prayer_schedule", "[]") ?: "[]"
        try {
            val prayers = JSONArray(raw)
            for (i in 0 until prayers.length()) {
                val item = prayers.getJSONObject(i)
                val timestamp = Instant.parse(item.getString("timestamp")).toEpochMilli()
                if (timestamp > now) {
                    nextName = if (locale.language == "ar") item.optString("arabicName", item.getString("name")) else item.getString("name")
                    nextAt = timestamp
                    nextTime = DateTimeFormatter.ofPattern(if (locale.language == "ar") "HH:mm" else "h:mm a", locale)
                        .withZone(java.time.ZoneId.systemDefault()).format(Instant.ofEpochMilli(timestamp))
                    break
                }
            }
        } catch (_: Exception) { }

        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.next_prayer_widget)
            views.setTextViewText(R.id.widget_hijri_date, hijriDate)
            if (enabled && nextAt > now) {
                views.setViewVisibility(R.id.widget_prayer_label, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_prayer_name, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_prayer_time, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_countdown, android.view.View.VISIBLE)
                views.setTextViewText(R.id.widget_prayer_label, if (locale.language == "ar") "الصلاة القادمة" else "Next prayer")
                views.setTextViewText(R.id.widget_prayer_name, nextName)
                views.setTextViewText(R.id.widget_prayer_time, nextTime)
                views.setChronometer(R.id.widget_countdown, SystemClock.elapsedRealtime() + (nextAt - now), "%s", true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    views.setChronometerCountDown(R.id.widget_countdown, true)
                }
                scheduleRefresh(context, nextAt)
            } else {
                views.setTextViewText(R.id.widget_prayer_label, if (locale.language == "ar") "فعّل الويدجت من الإعدادات" else "Enable widget in Settings")
                views.setViewVisibility(R.id.widget_prayer_name, android.view.View.GONE)
                views.setViewVisibility(R.id.widget_prayer_time, android.view.View.GONE)
                views.setViewVisibility(R.id.widget_countdown, android.view.View.GONE)
            }
            manager.updateAppWidget(id, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            val manager = AppWidgetManager.getInstance(context)
            onUpdate(context, manager, manager.getAppWidgetIds(android.content.ComponentName(context, NextPrayerWidgetProvider::class.java)))
        }
    }

    private fun scheduleRefresh(context: Context, at: Long) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, NextPrayerWidgetProvider::class.java).setAction(ACTION_REFRESH)
        val pending = PendingIntent.getBroadcast(context, 7412, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at + 1000, pending)
        } else {
            alarm.set(AlarmManager.RTC_WAKEUP, at + 1000, pending)
        }
    }

    companion object {
        private const val ACTION_REFRESH = "com.salawat_quran.NEXT_PRAYER_WIDGET_REFRESH"
    }
}
KOTLIN

cat > android/app/src/main/res/layout/next_prayer_widget.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#103C32"
    android:orientation="vertical"
    android:padding="14dp">
    <TextView
        android:id="@+id/widget_hijri_date"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="#FFE7A3"
        android:textSize="12sp"
        android:maxLines="1" />
    <TextView
        android:id="@+id/widget_prayer_label"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="7dp"
        android:text="Next prayer"
        android:textColor="#E6EDE9"
        android:textSize="11sp" />
    <TextView
        android:id="@+id/widget_prayer_name"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textColor="#FFFFFF"
        android:textSize="18sp"
        android:textStyle="bold"
        android:maxLines="1" />
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center_vertical">
        <TextView
            android:id="@+id/widget_prayer_time"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:textColor="#FFE7A3"
            android:textSize="13sp" />
        <Chronometer
            android:id="@+id/widget_countdown"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="10dp"
            android:textColor="#FFFFFF"
            android:textSize="15sp"
            android:textStyle="bold" />
    </LinearLayout>
</LinearLayout>
XML

cat > android/app/src/main/res/xml/next_prayer_widget_info.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:description="@string/next_prayer_widget_description"
    android:initialLayout="@layout/next_prayer_widget"
    android:minWidth="180dp"
    android:minHeight="100dp"
    android:previewLayout="@layout/next_prayer_widget"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="1800000"
    android:widgetCategory="home_screen" />
XML

python3 - <<'PY'
from pathlib import Path
p = Path('android/app/src/main/AndroidManifest.xml')
s = p.read_text()
receiver = '''
        <receiver
            android:name=".NextPrayerWidgetProvider"
            android:exported="true"
            android:label="Next Prayer">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
                <action android:name="com.salawat_quran.NEXT_PRAYER_WIDGET_REFRESH" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/next_prayer_widget_info" />
        </receiver>
'''
if 'NextPrayerWidgetProvider' not in s:
    pos = s.rfind('</application>')
    if pos < 0:
        raise SystemExit('AndroidManifest has no application closing tag')
    s = s[:pos] + receiver + s[pos:]
p.write_text(s)

strings = Path('android/app/src/main/res/values/strings.xml')
if strings.exists():
    value = strings.read_text()
else:
    strings.parent.mkdir(parents=True, exist_ok=True)
    value = '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n</resources>\n'
if 'next_prayer_widget_description' not in value:
    value = value.replace('</resources>', '    <string name="next_prayer_widget_description">Hijri date, next prayer and live countdown</string>\n</resources>')
strings.write_text(value)
PY
