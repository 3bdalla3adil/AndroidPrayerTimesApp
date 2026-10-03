package com.example.target.ui.reminder;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import com.example.target.PrayerAlarmScheduler;
import com.example.target.QuranActivity;
import com.example.target.R;

public class ReminderFragment extends Fragment {

    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            ViewGroup container,
            Bundle savedInstanceState
    ) {
        View root = inflater.inflate(R.layout.fragment_reminder, container, false);

        TextView status = root.findViewById(R.id.reminder_status);
        root.findViewById(R.id.schedule_athan).setOnClickListener(v -> {
            PrayerAlarmScheduler.scheduleNextDay(requireContext());
            status.setText("تمت جدولة تنبيهات الفجر والظهر والعصر والمغرب والعشاء محلياً.");
            Toast.makeText(requireContext(), "تم تفعيل تنبيهات الأذان", Toast.LENGTH_SHORT).show();
        });

        root.findViewById(R.id.open_quran).setOnClickListener(v ->
                startActivity(new Intent(requireContext(), QuranActivity.class)));

        PrayerAlarmScheduler.scheduleNextDay(requireContext());
        return root;
    }
}
