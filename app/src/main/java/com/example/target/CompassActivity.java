package com.example.target;

import android.hardware.Sensor;
import android.hardware.SensorManager;

import android.os.Build;
import android.view.Menu;
import android.view.MenuItem;
import android.view.animation.Animation;
import android.view.animation.RotateAnimation;
import android.hardware.SensorEvent;
import android.widget.ImageView;
import android.widget.TextView;
import android.hardware.SensorEventListener;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;
import androidx.navigation.NavController;
import androidx.navigation.Navigation;

import com.example.target.ui.calender.CalenderFragment;
import com.example.target.ui.hijri.HijriFragment;

import com.example.target.ui.home.HomeFragment;
import com.example.target.ui.reminder.ReminderFragment;

import static android.hardware.Sensor.TYPE_ORIENTATION;

@androidx.annotation.RequiresApi(api = Build.VERSION_CODES.CUPCAKE)
public class CompassActivity extends AppCompatActivity implements SensorEventListener {
    // device sensor manager
    private SensorManager SensorManage;
    // define the compass picture that will be use
    private ImageView compassimage;
    // record the angle turned of the compass picture
    private float DegreeStart = 0f;
    TextView DegreeTV;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_compass);
        //
        compassimage = findViewById(R.id.compass_image);
        // TextView that will display the degree
        DegreeTV = findViewById(R.id.DegreeTV);
        // initialize your android device sensor capabilities
        SensorManage = (SensorManager) getSystemService(SENSOR_SERVICE);
    }


    @Override
    protected void onPause() {
        super.onPause();
        // to stop the listener and save battery
            SensorManage.unregisterListener(this);
    }

    @Override
    protected void onDestroy() {

        super.onDestroy();
    }

    @Override
    protected void onResume() {
        super.onResume();
        // code for system's orientation sensor registered listeners
            SensorManage.registerListener(this, SensorManage.getDefaultSensor(TYPE_ORIENTATION),
                    SensorManager.SENSOR_DELAY_GAME);


    }
    @Override
    public void onSensorChanged(SensorEvent event) {
        // get angle around the z-axis rotated
        float degree = 0;

            degree = Math.round(event.values[0]);

        DegreeTV.setText("Heading: " + degree + " degrees");
        // rotation animation - reverse turn degree degrees
        RotateAnimation ra = new RotateAnimation(
                DegreeStart,
                -degree,
                Animation.RELATIVE_TO_SELF, 0.5f,
                Animation.RELATIVE_TO_SELF, 0.5f);
        // set the compass animation after the end of the reservation status
        ra.setFillAfter(true);
        // set how long the animation for the compass image will take place
        ra.setDuration(210);
        // Start animation of compass image
        compassimage.startAnimation(ra);
        DegreeStart = -degree;
    }
    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // not in use
    }

    private void loadFragment(Fragment fragment) {
        // create a FragmentManager
        FragmentManager fm = getSupportFragmentManager();
        // FragmentManager fm = getFragmentManager();
        // create a FragmentTransaction to begin the transaction and replace the Fragment
        FragmentTransaction fragmentTransaction = fm.beginTransaction();
        // replace the FrameLayout with new Fragment
        fragmentTransaction.replace(R.id.home_fragment, fragment);
        fragmentTransaction.addToBackStack(null);
        fragmentTransaction.commit(); // save the changes
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.main, menu);

        return true;
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {

        int id = item.getItemId();

        switch (id) {

            case R.id.reminderitem: {
                loadFragment(new ReminderFragment());
                break;
            }

            case R.id.calenderitem:{
                loadFragment(new CalenderFragment());
                break;
            }

            case R.id.homeitem:{
                loadFragment(new HomeFragment());
                break;}

            case R.id.hiriItem:{
                loadFragment(new HijriFragment());
                break;}
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public boolean onSupportNavigateUp() {
        NavController navController = Navigation.findNavController(this, R.id.home_fragment);
        return  super.onSupportNavigateUp();
    }
}
