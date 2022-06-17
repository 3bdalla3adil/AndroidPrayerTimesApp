package com.example.target.decorators;

import android.app.Activity;
import android.graphics.drawable.Drawable;

import androidx.fragment.app.Fragment;

import com.example.target.materialhijricalendarview.CalendarDay;
import com.example.target.materialhijricalendarview.DayViewDecorator;
import com.example.target.materialhijricalendarview.DayViewFacade;
import com.example.target.R;

/**
 * Use a custom selector
 */
public class MySelectorDecorator implements DayViewDecorator {

    private final Drawable drawable;

    public MySelectorDecorator(Activity context) {
        drawable = context.getResources().getDrawable(R.drawable.my_selector);
    }

    @Override
    public boolean shouldDecorate(CalendarDay day) {
        return true;
    }

    @Override
    public void decorate(DayViewFacade view) {
        view.setSelectionDrawable(drawable);
    }
}
