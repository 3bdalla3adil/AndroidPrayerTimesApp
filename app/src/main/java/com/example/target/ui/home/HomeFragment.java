package com.example.target.ui.home;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;

import com.example.target.CompassActivity;
import com.example.target.QuranActivity;
import com.example.target.R;
import com.example.target.ui.calender.CalenderFragment;
import com.example.target.ui.prayertimes.PrayerTimesFragment;
import com.example.target.ui.reminder.ReminderFragment;

import org.joda.time.DateTime;

public class HomeFragment extends Fragment {

    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            ViewGroup container,
            Bundle savedInstanceState
    ) {
        View root = inflater.inflate(R.layout.fragment_home, container, false);

        TextView date = root.findViewById(R.id.textView2);
        Button qibla = root.findViewById(R.id.compassbutton);
        Button calendar = root.findViewById(R.id.calenderButton);
        Button prayers = root.findViewById(R.id.salawatbutton);
        Button reminder = root.findViewById(R.id.reminder);
        Button hijri = root.findViewById(R.id.hijributton);
        Button quran = root.findViewById(R.id.quranbutton);

        date.setText(DateTime.now().toYearMonthDay().toString());

        qibla.setOnClickListener(v ->
                startActivity(new Intent(requireContext(), CompassActivity.class)));
        quran.setOnClickListener(v ->
                startActivity(new Intent(requireContext(), QuranActivity.class)));
        prayers.setOnClickListener(v -> loadFragment(new PrayerTimesFragment()));
        calendar.setOnClickListener(v -> loadFragment(new CalenderFragment()));
        reminder.setOnClickListener(v -> loadFragment(new ReminderFragment()));

        hijri.setOnClickListener(v -> {
            Intent intent = new Intent(requireContext(), com.example.target.BasicActivityDecorated.class);
            startActivity(intent);
        });

        return root;
    }

    private void loadFragment(Fragment fragment) {
        FragmentManager fm = requireActivity().getSupportFragmentManager();
        FragmentTransaction transaction = fm.beginTransaction();
        transaction.replace(R.id.home_fragment, fragment);
        transaction.addToBackStack(null);
        transaction.commit();
    }
}
