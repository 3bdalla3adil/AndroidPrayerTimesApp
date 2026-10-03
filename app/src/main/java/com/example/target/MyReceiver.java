package com.example.target;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.MediaPlayer;
import android.os.Build;

import androidx.core.app.NotificationCompat;

public class MyReceiver extends BroadcastReceiver {
    private static final String CHANNEL_ID = "athan";

    @Override
    public void onReceive(Context context, Intent intent) {
        String prayer = intent.getStringExtra("prayer_name");
        if (prayer == null) prayer = "Prayer";

        createChannel(context);

        Intent open = new Intent(context, MainActivity.class);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        PendingIntent contentIntent = PendingIntent.getActivity(context, 9000, open, flags);

        NotificationManager manager =
                (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager != null) {
            NotificationCompat.Builder builder = new NotificationCompat.Builder(context, CHANNEL_ID)
                    .setSmallIcon(R.mipmap.salat144xx_3)
                    .setContentTitle("حان وقت الصلاة")
                    .setContentText(prayer)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setAutoCancel(true)
                    .setContentIntent(contentIntent);
            manager.notify(prayer.hashCode(), builder.build());
        }

        MediaPlayer player = MediaPlayer.create(context, R.raw.azan);
        if (player != null) {
            player.setOnCompletionListener(MediaPlayer::release);
            player.start();
        }

        // Recalculate tomorrow's alarms so the schedule follows the calendar.
        PrayerAlarmScheduler.scheduleNextDay(context);
    }

    private void createChannel(Context context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;

        NotificationManager manager =
                (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) return;

        NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Athan reminders",
                NotificationManager.IMPORTANCE_HIGH
        );
        channel.setDescription("Prayer time reminders with Athan");
        manager.createNotificationChannel(channel);
    }
}
