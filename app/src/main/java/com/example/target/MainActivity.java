package com.example.target;

import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;

import com.example.target.ui.calender.CalenderFragment;
import com.example.target.ui.hijri.HijriFragment;
import com.example.target.ui.home.HomeFragment;
import com.example.target.ui.prayertimes.PrayerTimesFragment;
import com.example.target.ui.reminder.ReminderFragment;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        PrayerAlarmScheduler.scheduleNextDay(this);
    }

    private void loadFragment(Fragment fragment) {
        FragmentManager fm = getSupportFragmentManager();
        FragmentTransaction transaction = fm.beginTransaction();
        transaction.replace(R.id.home_fragment, fragment);
        transaction.addToBackStack(null);
        transaction.commit();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.reminderitem:
                loadFragment(new ReminderFragment());
                return true;
            case R.id.calenderitem:
                loadFragment(new CalenderFragment());
                return true;
            case R.id.homeitem:
                loadFragment(new HomeFragment());
                return true;
            case R.id.hiriItem:
                loadFragment(new HijriFragment());
                return true;
            case R.id.prayertimesitem:
                loadFragment(new PrayerTimesFragment());
                return true;
            case R.id.quranitem:
                startActivity(new android.content.Intent(this, QuranActivity.class));
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }
}
