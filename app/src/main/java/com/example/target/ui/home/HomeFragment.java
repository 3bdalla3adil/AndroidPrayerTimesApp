package com.example.target.ui.home;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;
import androidx.lifecycle.ViewModelProviders;

import com.example.target.BasicActivity;
import com.example.target.BasicActivityDecorated;
import com.example.target.CompassActivity;
import com.example.target.Coordinates;
import com.example.target.Prayer;
import com.example.target.PrayerTimes;
import com.example.target.R;
import com.example.target.ui.calender.CalenderFragment;
import com.example.target.ui.hijri.HijriFragment;
import com.example.target.ui.prayertimes.PrayerTimesFragment;
import com.example.target.ui.reminder.ReminderFragment;

import org.joda.time.DateTime;
import org.json.JSONException;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.util.Calendar;

@RequiresApi(api = Build.VERSION_CODES.KITKAT)
public class HomeFragment extends Fragment {


//    private RequestQueue mQueue;
    private String data;
    Calendar c = Calendar.getInstance();
    int month = c.get(Calendar.MONTH) + 1;
    int year = c.get(Calendar.YEAR);
    int date = c.get(Calendar.DAY_OF_MONTH);
    PrayerTimes prayerTimes ;

    public View onCreateView(@NonNull LayoutInflater inflater,
                             final ViewGroup container, Bundle savedInstanceState) {
        HomeViewModel homeViewModel = ViewModelProviders.of(this).get(HomeViewModel.class);


        View root = inflater.inflate(R.layout.fragment_home, container, false);

        final TextView tv = root.findViewById(R.id.textView2);
        final Button qibla = root.findViewById(R.id.compassbutton);
        final Button calender = root.findViewById(R.id.calenderButton);
        final Button salawat = root.findViewById(R.id.salawatbutton);
        final Button reminder = root.findViewById(R.id.reminder);
        final Button hijri = root.findViewById(R.id.hijributton);

//        Main Date Text View

        tv.setText(DateTime.now().toYearMonthDay().toString());

//        tv.setText(prayerTimes.currentPrayer().toString());


// Buttons :   6 Buuttons

        qibla.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(getActivity(), CompassActivity.class);
                startActivity(intent);
            }
        });

        salawat.setOnClickListener(new View.OnClickListener() {
            @RequiresApi(api = Build.VERSION_CODES.KITKAT)
            @Override
            public void onClick(View view) {
                loadFragment(new PrayerTimesFragment());

            }
        });

        calender.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                loadFragment(new CalenderFragment());
            }
        });

        hijri.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent hijriintent = new Intent(getActivity(), BasicActivityDecorated.class);
                startActivity(hijriintent);
            }
        });

        reminder.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                loadFragment(new ReminderFragment());

            }
        });


        return root;
    }

    private void loadFragment(Fragment fragment) {
        // create a FragmentManager
        FragmentManager fm = getActivity().getSupportFragmentManager();
        // FragmentManager fm = getFragmentManager();
        // create a FragmentTransaction to begin the transaction and replace the Fragment
        FragmentTransaction fragmentTransaction = fm.beginTransaction();
        // replace the FrameLayout with new Fragment
        fragmentTransaction.replace(R.id.home_fragment, fragment);
        fragmentTransaction.addToBackStack(null);
        fragmentTransaction.commit(); // save the changes
    }

}