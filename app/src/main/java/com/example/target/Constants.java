package com.example.target;

import com.example.target.data.DateComponents;

import java.util.Calendar;
import java.util.Date;

public class Constants {
    String Isha, Magrib, Asrr, Dhur, Fajr, Imsak;
    Calendar c = Calendar.getInstance();
    int day = c.get(Calendar.DAY_OF_MONTH), months, years, index = day - 1;

    final Coordinates coordinates = new Coordinates(15.6, 32.51);
    final DateComponents dateComponents = DateComponents.from(new Date());
    final CalculationParameters parameters =
            CalculationMethod.EGYPTIAN.getParameters();

    PrayerTimes prayerTimes = new PrayerTimes(coordinates, dateComponents, parameters);
}
