package com.example.target;

import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import java.util.Locale;

/**
 * Offline Qibla compass. Uses the device rotation-vector sensor and the
 * existing spherical Qibla calculation; no maps or network services.
 */
public class CompassActivity extends AppCompatActivity implements SensorEventListener {
    private SensorManager sensorManager;
    private Sensor rotationSensor;
    private ImageView compassImage;
    private TextView degreeText;
    private float[] rotationMatrix = new float[9];
    private float[] orientation = new float[3];
    private float qiblaBearing;
    private float lastRotation = 0f;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_compass);

        compassImage = findViewById(R.id.compass_image);
        degreeText = findViewById(R.id.DegreeTV);

        sensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);
        rotationSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR);

        qiblaBearing = (float) new Qibla(new Coordinates(15.6, 32.51)).direction;
        degreeText.setText(String.format(
                Locale.getDefault(),
                "Qibla: %.0f°",
                qiblaBearing
        ));
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (rotationSensor != null) {
            sensorManager.registerListener(
                    this,
                    rotationSensor,
                    SensorManager.SENSOR_DELAY_GAME
            );
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        sensorManager.unregisterListener(this);
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() != Sensor.TYPE_ROTATION_VECTOR) return;

        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values);
        SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_X,
                SensorManager.AXIS_Y,
                rotationMatrix
        );
        SensorManager.getOrientation(rotationMatrix, orientation);

        float heading = (float) Math.toDegrees(orientation[0]);
        heading = (heading + 360f) % 360f;

        float qiblaRelative = qiblaBearing - heading;
        if (qiblaRelative < -180f) qiblaRelative += 360f;
        if (qiblaRelative > 180f) qiblaRelative -= 360f;

        compassImage.setRotation(-qiblaRelative);
        degreeText.setText(String.format(
                Locale.getDefault(),
                "Qibla %.0f°  •  Heading %.0f°",
                qiblaBearing,
                heading
        ));
        lastRotation = qiblaRelative;
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // No calibration state is persisted; Android's sensor stack handles it.
    }
}
