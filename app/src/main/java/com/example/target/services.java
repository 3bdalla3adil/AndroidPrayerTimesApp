package com.example.target;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.IBinder;
import android.provider.Settings;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import com.example.target.data.DateComponents;

import org.joda.time.DateTime;

import java.util.Calendar;
import java.util.Date;
import java.util.Locale;

import static android.util.Log.VERBOSE;

@RequiresApi(api = Build.VERSION_CODES.KITKAT)
public class services extends Service {

    public static final int REQUEST_CODE = 101;

    private Calendar calender = Calendar.getInstance();

    @Override
    public void onCreate() {
        super.onCreate();

    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {

        Log.println(VERBOSE, "Tag", "Service Started" +
                "" + "<<======");


        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }


}
