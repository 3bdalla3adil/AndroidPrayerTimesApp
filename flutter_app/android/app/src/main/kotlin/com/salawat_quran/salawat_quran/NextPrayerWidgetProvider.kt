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
