package com.example.target;

import android.content.SharedPreferences;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Locale;

/** Simple, fast, fully offline Arabic Quran reader. */
public class QuranReaderActivity extends AppCompatActivity {
    private static final String PREFS = "quran_reader";
    private LinearLayout verses;
    private int surahNumber;
    private SharedPreferences prefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_quran_reader);

        surahNumber = getIntent().getIntExtra("surah", 1);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        verses = findViewById(R.id.quran_verses);

        findViewById(R.id.quran_reader_back).setOnClickListener(v -> finish());
        findViewById(R.id.quran_bookmark).setOnClickListener(v -> {
            prefs.edit().putInt("last_surah", surahNumber).apply();
            Toast.makeText(this, "تم حفظ آخر موضع قراءة", Toast.LENGTH_SHORT).show();
        });

        loadSurah();
    }

    private void loadSurah() {
        new Thread(() -> {
            try {
                JSONObject root = new JSONObject(readAsset(
                        "quran/" + String.format(Locale.US, "%03d.json", surahNumber)
                ));
                runOnUiThread(() -> render(root));
            } catch (Exception e) {
                runOnUiThread(() ->
                        Toast.makeText(this, "بيانات السورة غير متوفرة", Toast.LENGTH_LONG).show());
            }
        }).start();
    }

    private void render(JSONObject root) {
        TextView title = findViewById(R.id.quran_surah_title);
        title.setText(root.optString("name", "Quran"));
        verses.removeAllViews();

        JSONObject verseObject = root.optJSONObject("verse");
        if (verseObject == null) return;

        int count = root.optInt("count", verseObject.length());
        for (int i = 1; i <= count; i++) {
            String text = verseObject.optString("verse_" + i, "");
            if (text.isEmpty()) continue;

            TextView verse = new TextView(this);
            verse.setText(String.format(Locale.getDefault(), "%s  ﴿%d﴾", text, i));
            verse.setTextSize(25);
            verse.setTypeface(Typeface.create("sans-serif", Typeface.NORMAL));
            verse.setGravity(Gravity.RIGHT);
            verse.setTextDirection(android.view.View.TEXT_DIRECTION_RTL);
            verse.setLineSpacing(10, 1.15f);
            verse.setPadding(22, 20, 22, 20);
            verses.addView(verse);
        }
    }

    private String readAsset(String path) throws Exception {
        InputStream input = getAssets().open(path);
        BufferedReader reader = new BufferedReader(new InputStreamReader(input, "UTF-8"));
        StringBuilder out = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) out.append(line);
        reader.close();
        return out.toString();
    }
}
