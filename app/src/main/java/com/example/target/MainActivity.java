package com.example.target;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;
import androidx.navigation.NavController;
import androidx.navigation.Navigation;

import com.example.target.data.DateComponents;
import com.example.target.ui.calender.CalenderFragment;
import com.example.target.ui.hijri.HijriFragment;
import com.example.target.ui.home.HomeFragment;
import com.example.target.ui.prayertimes.PrayerTimesFragment;
import com.example.target.ui.reminder.ReminderFragment;

import java.util.Calendar;
import java.util.Date;

import static com.example.target.services.REQUEST_CODE;

public class MainActivity extends AppCompatActivity {

    TextView textDate;

    Calendar c = Calendar.getInstance();
    int month = c.get(Calendar.MONTH) + 1;
    int year = c.get(Calendar.YEAR);
    int date = c.get(Calendar.DAY_OF_MONTH);

    private Calendar calender = Calendar.getInstance();

    private String Fajr;
    private String Dhur;
    private String Asrr;
    private String Magrib;
    private String Isha;

    final Coordinates coordinates = new Coordinates(15.6, 32.51);
    final DateComponents dateComponents = DateComponents.from(new Date());
    final CalculationParameters parameters =
            CalculationMethod.EGYPTIAN.getParameters();

    PrayerTimes prayerTimes = new PrayerTimes(coordinates, dateComponents, parameters);
    private PendingIntent alarmIntent;
    private AlarmManager alarmMgr;

    @Override
    protected void onCreate(Bundle onSaveInstanceState) {
        super.onCreate(onSaveInstanceState);
        setContentView(R.layout.activity_main);
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        toast(month + "-" + year);
        textDate = findViewById(R.id.textView2);

        alarmMgr = (AlarmManager) getApplicationContext().getSystemService(Context.ALARM_SERVICE);

        Intent intent = new Intent(this, MyReceiver.class);

//        alarmIntent = PendingIntent.getBroadcast(this, 0, intent, 0);

        calender.setTimeInMillis(System.currentTimeMillis());

//        calender.set(Calendar.HOUR_OF_DAY, prayerTimes.fajr.getHours(), prayerTimes.fajr.getMinutes());
//        calender.set(Calendar.MINUTE, prayerTimes.fajr.getMinutes());
//        calender.set(Calendar.HOUR_OF_DAY, prayerTimes.dhuhr.getHours(), prayerTimes.dhuhr.getMinutes());
//        calender.set(Calendar.MINUTE, prayerTimes.dhuhr.getMinutes());
//        calender.set(Calendar.HOUR_OF_DAY, prayerTimes.asr.getHours(), prayerTimes.asr.getMinutes());
//        calender.set(Calendar.MINUTE, prayerTimes.asr.getMinutes());
//        calender.set(Calendar.HOUR_OF_DAY, prayerTimes.maghrib.getHours(), prayerTimes.maghrib.getMinutes());
//        calender.set(Calendar.MINUTE, prayerTimes.maghrib.getMinutes());
//        calender.set(Calendar.HOUR_OF_DAY, prayerTimes.isha.getHours(), prayerTimes.isha.getMinutes());
//        calender.set(Calendar.MINUTE, prayerTimes.isha.getMinutes());

        alarmMgr.setRepeating(AlarmManager.RTC_WAKEUP, calender.getTimeInMillis(),
                AlarmManager.INTERVAL_DAY, alarmIntent);

        if (alarmMgr != null)
            alarmMgr.setInexactRepeating(AlarmManager.RTC,
                    calender.getTimeInMillis(),
                    AlarmManager.INTERVAL_DAY, alarmIntent);

//        if (calender.getTimeInMillis() == prayerTimes.isha.getHours() * 60 * 60 * 1000)

        Log.i("TAG0", String.valueOf(calender.getTimeInMillis()));
        Log.i("TAG1", String.valueOf(calender.getTimeInMillis()/60*60*1000));
        Log.i("TAG2", String.valueOf(System.currentTimeMillis()/1000*60*60));
//        if (calender.getTimeInMillis() == 20 * 60 * 60 * 1000)

//            startService(new Intent(getApplicationContext(), services.class));

//        calender.set(Calendar.HOUR_OF_DAY, prayerTimes.isha.getHours());
//        Log.i("TAG", String.valueOf(calender.getTimeInMillis()));
//
//        calender.set(Calendar.MINUTE, prayerTimes.isha.getMinutes());
//        Log.i("TAG", String.valueOf(calender.getTimeInMillis()));

        calender.set(Calendar.HOUR_OF_DAY, (int) prayerTimes.isha.getTime());
        Log.i("TAG3", String.valueOf(calender.getTimeInMillis()));

    }


    @Override
    protected void onPause() {
        super.onPause();
    }

    public void toast(String error) {
        Toast.makeText(this, error, Toast.LENGTH_LONG).show();
    }

    private void loadFragment(Fragment fragment) {
        // create a FragmentManager
        FragmentManager fm = getSupportFragmentManager();
        // FragmentManager fm = getFragmentManager();
        // create a FragmentTransaction to begin the transaction and replace the Fragment
        FragmentTransaction fragmentTransaction = fm.beginTransaction();
        // replace the FrameLayout with new Fragment
        fragmentTransaction.replace(R.id.home_fragment, fragment);
        fragmentTransaction.addToBackStack(null);
        fragmentTransaction.commit(); // save the changes
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.main, menu);

        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        int id = item.getItemId();

        switch (id) {

            case R.id.reminderitem: {
                loadFragment(new ReminderFragment());
                break;
            }

            case R.id.calenderitem: {
                loadFragment(new CalenderFragment());
                break;
            }

            case R.id.homeitem: {
                loadFragment(new HomeFragment());
                break;
            }

            case R.id.hiriItem: {
                loadFragment(new HijriFragment());
                break;
            }

            case R.id.prayertimesitem: {
                loadFragment(new PrayerTimesFragment());
                break;
            }
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public boolean onSupportNavigateUp() {
        NavController navController = Navigation.findNavController(this, R.id.home_fragment);
        return super.onSupportNavigateUp();
    }
}
