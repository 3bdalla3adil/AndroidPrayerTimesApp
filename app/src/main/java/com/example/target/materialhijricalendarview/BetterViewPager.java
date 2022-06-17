package com.example.target.materialhijricalendarview;

import android.content.Context;
import android.util.AttributeSet;

import androidx.viewpager.widget.ViewPager;

/**
 * {@linkplain #setChildrenDrawingOrderEnabledCompat(boolean)} does some reflection that isn't needed.
 * And was making view creation time rather large. So lets override it and make it better!
 */
public class BetterViewPager extends ViewPager {

    public BetterViewPager(Context context) {
        super(context);
    }

    public BetterViewPager(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public void setChildrenDrawingOrderEnabledCompat(boolean enable) {
        setChildrenDrawingOrderEnabled(enable);
    }
}
