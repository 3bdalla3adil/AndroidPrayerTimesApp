package com.example.target;

import android.annotation.SuppressLint;
import android.os.Build;
import android.os.Bundle;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;

import com.example.target.materialhijricalendarview.OnDateSelectedListener;
import com.example.target.materialhijricalendarview.OnMonthChangedListener;
import com.example.target.materialhijricalendarview.CalendarDay;
import com.example.target.materialhijricalendarview.MaterialHijriCalendarView;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;

import butterknife.BindView;
import butterknife.Unbinder;
import butterknife.ButterKnife;

/**
 * Shows off the most basic usage
 */
@RequiresApi (api = Build.VERSION_CODES.N)
public class BasicActivity extends AppCompatActivity implements OnDateSelectedListener, OnMonthChangedListener {

    @SuppressLint("SimpleDateFormat")
    private static DateFormat FORMATTER = new SimpleDateFormat("MMM d, y");

    @BindView(R.id.calendarView)
    MaterialHijriCalendarView widget;

    @BindView(R.id.textView)
    TextView textView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_basic);

        ButterKnife.bind(this);


//        widget.setOnDateChangedListener(this);
//        widget.setOnMonthChangedListener(this);

        //Setup initial text
        textView.setText(getSelectedDatesString());
    }


    public void onDateSelected(@NonNull MaterialHijriCalendarView widget, @Nullable CalendarDay date, boolean selected) {
        textView.setText(getSelectedDatesString());
    }


    public void onMonthChanged(MaterialHijriCalendarView widget, CalendarDay date) {
        //noinspection Constant Conditions
        FORMATTER.setCalendar(date.getCalendar());
//        getSupportActionBar().setTitle(FORMATTER.format(date.getCalendar().getTime()));
        getSupportActionBar().setTitle(date.getCalendar().getDisplayName(Calendar.MONTH, Calendar.SHORT, Locale.getDefault()) + " " + date.getCalendar().get(Calendar.DAY_OF_MONTH) + ", " + String.valueOf(date.getYear()));
    }

    private String getSelectedDatesString() {
        CalendarDay date = widget.getSelectedDate();
        if (date == null) {
            return "No Selection";
        }
        FORMATTER.setCalendar(date.getCalendar());
//        return FORMATTER.format(date.getCalendar().getTime());
        return date.getCalendar().getDisplayName(Calendar.MONTH, Calendar.SHORT, Locale.getDefault()) + " " + date.getCalendar().get(Calendar.DAY_OF_MONTH) + ", " + String.valueOf(date.getYear());

    }

    @Override
    public void onPointerCaptureChanged(boolean hasCapture) {

    }
}
