package com.example.target.decorators;

import android.graphics.Typeface;
import android.text.style.RelativeSizeSpan;
import android.text.style.StyleSpan;

import com.example.target.materialhijricalendarview.CalendarDay;
import com.example.target.materialhijricalendarview.DayViewDecorator;
import com.example.target.materialhijricalendarview.DayViewFacade;
import com.example.target.materialhijricalendarview.MaterialHijriCalendarView;

import java.util.Date;

/**
 * Decorate a day by making the text big and bold
 */
public class OneDayDecorator implements DayViewDecorator {

    private CalendarDay date;

    public OneDayDecorator() {
        date = CalendarDay.today();
    }

    @Override
    public boolean shouldDecorate(CalendarDay day) {
        return date != null && day.equals(date);
    }

    @Override
    public void decorate(DayViewFacade view) {
        view.addSpan(new StyleSpan(Typeface.BOLD));
        view.addSpan(new RelativeSizeSpan(1.4f));
    }

    /**
     * We're changing the internals, so make sure to call {@linkplain MaterialHijriCalendarView#invalidateDecorators()}
     */
    public void setDate(Date date) {
        this.date = CalendarDay.from(date);
    }
}
