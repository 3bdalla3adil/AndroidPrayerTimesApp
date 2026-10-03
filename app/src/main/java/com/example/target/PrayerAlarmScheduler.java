package com.example.target;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import com.example.target.data.DateComponents;

import java.util.Calendar;
import java.util.Date;

/**
 * Schedules the next prayer alarms using the same on-device calculation engine
 * used by the prayer-time screens. No network service is required.
 */
public final class PrayerAlarmScheduler {
    private static final double DEFAULT_LATITUDE = 15.6;
    private static final double DEFAULT_LONGITUDE = 32.51;
    private static final int[] REQUEST_CODES = {2001, 2002, 2003, 2004, 2005};

    private PrayerAlarmScheduler() {}

    public static void scheduleNextDay(Context context) {
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarmManager == null) return;

        Coordinates coordinates = new Coordinates(DEFAULT_LATITUDE, DEFAULT_LONGITUDE);
        PrayerTimes times = new PrayerTimes(
                coordinates,
                DateComponents.from(new Date()),
                CalculationMethod.EGYPTIAN.getParameters()
        );

        schedule(alarmManager, context, "Fajr", times.fajr.getTime(), REQUEST_CODES[0]);
        schedule(alarmManager, context, "Dhuhr", times.dhuhr.getTime(), REQUEST_CODES[1]);
        schedule(alarmManager, context, "Asr", times.asr.getTime(), REQUEST_CODES[2]);
        schedule(alarmManager, context, "Maghrib", times.maghrib.getTime(), REQUEST_CODES[3]);
        schedule(alarmManager, context, "Isha", times.isha.getTime(), REQUEST_CODES[4]);
    }

    private static void schedule(
            AlarmManager alarmManager,
            Context context,
            String prayer,
            double hour,
            int requestCode
    ) {
        Calendar trigger = Calendar.getInstance();
        int hours = (int) Math.floor(hour);
        int minutes = (int) Math.round((hour - hours) * 60.0);

        if (minutes >= 60) {
            hours++;
            minutes = 0;
        }

        trigger.set(Calendar.HOUR_OF_DAY, hours);
        trigger.set(Calendar.MINUTE, minutes);
        trigger.set(Calendar.SECOND, 0);
        trigger.set(Calendar.MILLISECOND, 0);

        if (trigger.before(Calendar.getInstance())) {
            trigger.add(Calendar.DAY_OF_YEAR, 1);
        }

        Intent intent = new Intent(context, MyReceiver.class);
        intent.putExtra("prayer_name", prayer);

        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }

        PendingIntent pendingIntent = PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                flags
        );

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    trigger.getTimeInMillis(),
                    pendingIntent
            );
        } else {
            alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    trigger.getTimeInMillis(),
                    pendingIntent
            );
        }
    }
}
