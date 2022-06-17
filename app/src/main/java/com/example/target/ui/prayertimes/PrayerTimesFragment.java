package com.example.target.ui.prayertimes;

import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProviders;

import com.example.target.CalculationMethod;
import com.example.target.CalculationParameters;
import com.example.target.Coordinates;
import com.example.target.PrayerTimes;
import com.example.target.R;
import com.example.target.data.DateComponents;

import org.joda.time.DateTime;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.InputStream;
import java.util.Calendar;
import java.util.Date;


@RequiresApi(api = Build.VERSION_CODES.KITKAT)
public class PrayerTimesFragment extends Fragment {


    private View root;
    private String json;
    InputStream is;
    TextView date, sbh, dhr, asr, mgrb, asha, hijri, gregori, imsak;
    String Isha, Magrib, Asrr, Dhur, Fajr, Imsak;
    Calendar c = Calendar.getInstance();
    int day = c.get(Calendar.DAY_OF_MONTH), months, years, index = day - 1;

    final Coordinates coordinates = new Coordinates(15.6, 32.51);
    final DateComponents dateComponents = DateComponents.from(new Date());
    final CalculationParameters parameters =
            CalculationMethod.EGYPTIAN.getParameters();

    PrayerTimes prayerTimes = new PrayerTimes(coordinates, dateComponents, parameters);


    public View onCreateView(@NonNull LayoutInflater inflater,
                             ViewGroup container, Bundle savedInstanceState) {
        root = inflater.inflate(R.layout.fragment_prayertimes, container, false);

        getJsonFileFromLocally();

        return root;
    }

    private void getJsonFileFromLocally() {

        months = c.get(Calendar.MONTH) + 1;
        years = c.get(Calendar.YEAR);

        Fajr  = String.format("%d:%d", prayerTimes.fajr.getHours()   , prayerTimes.fajr.getMinutes());
        Dhur  = String.format("%d:%d", prayerTimes.dhuhr.getHours()  , prayerTimes.dhuhr.getMinutes());
        Asrr  = String.format("%d:%d", prayerTimes.asr.getHours()    , prayerTimes.asr.getMinutes());
        Magrib= String.format("%d:%d", prayerTimes.maghrib.getHours(), prayerTimes.maghrib.getMinutes());
        Isha  = String.format("%d:%d", prayerTimes.isha.getHours()   , prayerTimes.isha.getMinutes());
        Imsak = String.format("%d:%d", prayerTimes.fajr.getHours()   , prayerTimes.fajr.getMinutes() - 10 < 0 ?
                60 - (prayerTimes.fajr.getMinutes() - 10) : prayerTimes.fajr.getMinutes() - 10 );


        date  = root.findViewById(R.id.curnt_date);
        sbh   = root.findViewById(R.id.sbh);
        dhr   = root.findViewById(R.id.dhr);
        asr   = root.findViewById(R.id.asr);
        mgrb  = root.findViewById(R.id.mgrb);
        asha  = root.findViewById(R.id.asha);
        imsak = root.findViewById(R.id.imsak);

//          setTexts
        date.setText(DateTime.now().toYearMonthDay().toString());

        sbh.setText  (Fajr);
        dhr.setText  (Dhur);
        asr.setText  (Asrr);
        mgrb.setText (Magrib);
        asha.setText (Isha);
        imsak.setText(Imsak);

    }

    public void toast(String text) {
        Toast.makeText(getContext(), text, Toast.LENGTH_LONG).show();
    }

}