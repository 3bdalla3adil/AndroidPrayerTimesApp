package com.example.target.ui.calender;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;

import com.example.target.R;

public class CalenderFragment extends Fragment {

    private calenderViewModel calenderViewModel;

    @Override
    public void onPause() {
        super.onPause();
    }

    public View onCreateView(@NonNull LayoutInflater inflater,
                             ViewGroup container, Bundle savedInstanceState) {
        calenderViewModel =
                ViewModelProviders.of(this).get(calenderViewModel.class);
        View root = inflater.inflate(R.layout.fragment_calender, container, false);

        return root;
    }

}