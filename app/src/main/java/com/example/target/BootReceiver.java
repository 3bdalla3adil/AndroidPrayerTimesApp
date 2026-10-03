package com.example.target;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Restores prayer reminders after Android restarts the device. */
public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())
                || Intent.ACTION_MY_PACKAGE_REPLACED.equals(intent.getAction())) {
            PrayerAlarmScheduler.scheduleNextDay(context);
        }
    }
}
