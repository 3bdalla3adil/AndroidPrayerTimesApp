package com.example.target;

import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.View;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Locale;

/**
 * Offline Madinah Mushaf reader.
 *
 * The build task packages all 604 Madinah pages into the APK. No Quran
 * content is requested at runtime.
 */
public class QuranReaderActivity extends AppCompatActivity {
    private static final int TOTAL_PAGES = 604;
    private static final String PREFS = "quran_reader";
    private SharedPreferences prefs;
    private LinearLayout verses;
    private TextView pageLabel;
    private TextView title;
    private int page = 1;

    private final int paper = Color.rgb(255, 253, 245);
    private final int background = Color.rgb(247, 243, 232);
    private final int green = Color.rgb(23, 76, 60);
    private final int gold = Color.rgb(198, 154, 69);
    private final int ink = Color.rgb(23, 35, 29);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_quran_reader);

        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        verses = findViewById(R.id.quran_verses);
        title = findViewById(R.id.quran_surah_title);
        pageLabel = findViewById(R.id.quran_page_label);

        page = getIntent().getIntExtra("page", 0);
        if (page < 1) {
            page = prefs.getInt("last_page", 1);
        }
        if (page < 1 || page > TOTAL_PAGES) page = 1;

        findViewById(R.id.quran_reader_back).setOnClickListener(v -> finish());
        findViewById(R.id.quran_bookmark).setOnClickListener(v -> {
            prefs.edit().putInt("last_page", page).apply();
            Toast.makeText(this, "تم حفظ الصفحة " + page, Toast.LENGTH_SHORT).show();
        });
        findViewById(R.id.quran_prev).setOnClickListener(v -> showPage(page - 1));
        findViewById(R.id.quran_next).setOnClickListener(v -> showPage(page + 1));
        findViewById(R.id.quran_jump).setOnClickListener(v -> jumpToPage());

        showPage(page);
    }

    private void jumpToPage() {
        final EditText input = new EditText(this);
        input.setHint("رقم الصفحة 1 - 604");
        input.setInputType(android.text.InputType.TYPE_CLASS_NUMBER);
        input.setText(String.valueOf(page));
        new androidx.appcompat.app.AlertDialog.Builder(this)
                .setTitle("انتقال إلى صفحة")
                .setView(input)
                .setNegativeButton("إلغاء", null)
                .setPositiveButton("انتقال", (dialog, which) -> {
                    try {
                        int target = Integer.parseInt(input.getText().toString().trim());
                        showPage(target);
                    } catch (Exception ignored) {
                        Toast.makeText(this, "رقم صفحة غير صالح", Toast.LENGTH_SHORT).show();
                    }
                }).show();
    }

    private void showPage(int target) {
        if (target < 1 || target > TOTAL_PAGES) {
            Toast.makeText(this, target < 1 ? "أنت في أول صفحة" : "أنت في آخر صفحة", Toast.LENGTH_SHORT).show();
            return;
        }
        page = target;
        prefs.edit().putInt("last_page", page).apply();
        pageLabel.setText(String.format(Locale.getDefault(), "صفحة %d من %d", page, TOTAL_PAGES));
        findViewById(R.id.quran_prev).setEnabled(page > 1);
        findViewById(R.id.quran_next).setEnabled(page < TOTAL_PAGES);

        new Thread(() -> {
            try {
                JSONObject root = new JSONObject(readAsset(
                        "quran/pages/" + String.format(Locale.US, "%03d.json", page)
                ));
                runOnUiThread(() -> render(root));
            } catch (Exception e) {
                runOnUiThread(() -> Toast.makeText(
                        this, "بيانات الصفحة غير متوفرة. أعد بناء التطبيق.", Toast.LENGTH_LONG).show());
            }
        }).start();
    }

    private void render(JSONObject root) {
        verses.removeAllViews();
        JSONObject data = root.optJSONObject("data");
        JSONArray ayahs = data == null ? null : data.optJSONArray("ayahs");

        if (ayahs == null || ayahs.length() == 0) {
            title.setText("القرآن الكريم");
            return;
        }

        String surahName = ayahs.optJSONObject(0)
                .optJSONObject("surah")
                .optString("name", "القرآن الكريم");
        title.setText(surahName);

        int lastSurah = -1;
        for (int i = 0; i < ayahs.length(); i++) {
            JSONObject ayah = ayahs.optJSONObject(i);
            if (ayah == null) continue;

            JSONObject surah = ayah.optJSONObject("surah");
            int surahNumber = surah == null ? 0 : surah.optInt("number", 0);
            String name = surah == null ? "" : surah.optString("name", "");
            int verseNumber = ayah.optInt("numberInSurah", 0);
            String text = ayah.optString("text", "").trim();

            if (surahNumber != lastSurah && !TextUtils.isEmpty(name)) {
                addSurahHeader(name);
                lastSurah = surahNumber;
            }

            if (!text.isEmpty()) {
                TextView verse = new TextView(this);
                verse.setText(String.format(Locale.getDefault(),
                        "%s  ﴿%d﴾", text, verseNumber));
                verse.setTextSize(25);
                verse.setTextColor(ink);
                verse.setTypeface(Typeface.create("sans-serif", Typeface.NORMAL));
                verse.setGravity(Gravity.RIGHT);
                verse.setTextDirection(View.TEXT_DIRECTION_RTL);
                verse.setLineSpacing(12, 1.45f);
                verse.setPadding(16, 10, 16, 10);
                verses.addView(verse);
            }
        }

        if (page == TOTAL_PAGES) addKhatmDua();
    }

    private void addSurahHeader(String name) {
        TextView header = new TextView(this);
        header.setText(name);
        header.setTextSize(21);
        header.setTextColor(green);
        header.setTypeface(Typeface.DEFAULT_BOLD);
        header.setGravity(Gravity.CENTER);
        header.setTextDirection(View.TEXT_DIRECTION_RTL);
        header.setPadding(12, 22, 12, 12);
        verses.addView(header);
    }

    private void addKhatmDua() {
        TextView divider = new TextView(this);
        divider.setText("✦  دُعَاءُ خَتْمِ الْقُرْآنِ  ✦");
        divider.setTextSize(20);
        divider.setTextColor(gold);
        divider.setGravity(Gravity.CENTER);
        divider.setTypeface(Typeface.DEFAULT_BOLD);
        divider.setTextDirection(View.TEXT_DIRECTION_RTL);
        divider.setPadding(12, 28, 12, 14);
        verses.addView(divider);

        TextView dua = new TextView(this);
        dua.setText(
                "اللهم ارحمني بالقرآن، واجعله لي إماماً ونوراً وهدىً ورحمة. " +
                "اللهم ذكّرني منه ما نسيت، وعلّمني منه ما جهلت، وارزقني تلاوته آناء الليل وأطراف النهار، " +
                "واجعله لي حجة يا رب العالمين. اللهم أصلح لي ديني الذي هو عصمة أمري، وأصلح لي دنياي التي فيها معاشي، " +
                "وأصلح لي آخرتي التي إليها معادي، واجعل الحياة زيادة لي في كل خير، واجعل الموت راحة لي من كل شر. " +
                "اللهم اجعل القرآن ربيع قلبي، ونور صدري، وجلاء حزني، وذهاب همي."
        );
        dua.setTextSize(20);
        dua.setTextColor(ink);
        dua.setGravity(Gravity.RIGHT);
        dua.setTextDirection(View.TEXT_DIRECTION_RTL);
        dua.setLineSpacing(10, 1.45f);
        dua.setPadding(24, 18, 24, 30);
        verses.addView(dua);
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
