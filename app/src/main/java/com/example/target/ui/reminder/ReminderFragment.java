package com.example.target.ui.reminder;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;

import com.example.target.R;

public class ReminderFragment extends Fragment {

    private ReminderViewModel reminderViewModel;

    public View onCreateView(@NonNull LayoutInflater inflater,
                             ViewGroup container, Bundle savedInstanceState) {
        reminderViewModel =
                ViewModelProviders.of(this).get(ReminderViewModel.class);
        View root = inflater.inflate(R.layout.fragment_reminder, container, false);

        return root;
    }

}