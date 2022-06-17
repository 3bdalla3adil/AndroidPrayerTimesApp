package com.example.target.decorators;

import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;

import com.example.target.materialhijricalendarview.CalendarDay;
import com.example.target.materialhijricalendarview.DayViewDecorator;
import com.example.target.materialhijricalendarview.DayViewFacade;
import com.github.msarhan.ummalqura.calendar.UmmalquraCalendar;

import java.util.Calendar;

/**
 * Highlight Saturdays and Sundays with a background
 */
public class HighlightWeekendsDecorator implements DayViewDecorator {

    private static final int color = Color.parseColor("#228BC34A");
    private final UmmalquraCalendar calendar = new UmmalquraCalendar();
    private final Drawable highlightDrawable;

    public HighlightWeekendsDecorator() {
        highlightDrawable = new ColorDrawable(color);
    }

    @Override
    public boolean shouldDecorate(CalendarDay day) {
        day.copyTo(calendar);
        int weekDay = calendar.get(Calendar.DAY_OF_WEEK);
        return weekDay == Calendar.SATURDAY || weekDay == Calendar.SUNDAY;
    }

    @Override
    public void decorate(DayViewFacade view) {
        view.setBackgroundDrawable(highlightDrawable);
    }
}
