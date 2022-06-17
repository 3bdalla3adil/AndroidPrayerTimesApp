package com.example.target;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.MediaPlayer;
import android.provider.Settings;
import android.util.Log;
import android.widget.Toast;

import java.util.logging.Logger;

public class MyReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {

        MediaPlayer mediaPlayer = MediaPlayer.create(context, Settings.System.DEFAULT_RINGTONE_URI);//edited
//        MediaPlayer mediaPlayer = MediaPlayer.create(context, R.raw.azan);//edited
        mediaPlayer.start(); //edited

        Toast.makeText(context,"Alarm Triggered",Toast.LENGTH_LONG).show();
    }
}
