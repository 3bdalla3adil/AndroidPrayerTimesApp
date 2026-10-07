package com.example.target;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;

/** Offline Quran surah index. Quran data is packaged inside the APK. */
public class QuranActivity extends AppCompatActivity {
    private final List<SurahItem> allSurahs = new ArrayList<>();
    private LinearLayout list;
    private EditText search;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_quran);

        list = findViewById(R.id.quran_surah_list);
        search = findViewById(R.id.quran_search);

        findViewById(R.id.quran_back).setOnClickListener(v -> finish());
        search.addTextChangedListener(new android.text.TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int st, int c, int a) {}
            @Override public void onTextChanged(CharSequence s, int st, int b, int c) { render(s.toString()); }
            @Override public void afterTextChanged(android.text.Editable e) {}
        });

        loadIndex();
    }

    private void loadIndex() {
        new Thread(() -> {
            try {
                JSONObject pageIndex = new JSONObject(readAsset("quran/page-index.json"));
                JSONObject starts = pageIndex.optJSONObject("surahStartPages");
                String[] files = getAssets().list("quran");
                if (files != null) {
                    for (String file : files) {
                        if (!file.endsWith(".json")) continue;
                        String json = readAsset("quran/" + file);
                        JSONObject root = new JSONObject(json);
                        allSurahs.add(new SurahItem(
                                Integer.parseInt(root.optString("index", "0")),
                                root.optString("name", ""),
                                root.optInt("count", 0),
                                starts == null ? 1 : starts.optInt(root.optString("index", "1"), 1)
                        ));
                    }
                }
                Collections.sort(allSurahs, (a, b) -> Integer.compare(a.number, b.number));
                runOnUiThread(() -> render(""));
            } catch (Exception ignored) {
                runOnUiThread(() -> renderError());
            }
        }).start();
    }

    private void render(String query) {
        if (list == null) return;
        list.removeAllViews();
        String q = query.trim().toLowerCase(Locale.ROOT);

        for (SurahItem surah : allSurahs) {
            if (!q.isEmpty()
                    && !surah.name.toLowerCase(Locale.ROOT).contains(q)
                    && !String.valueOf(surah.number).equals(q)) {
                continue;
            }

            TextView row = new TextView(this);
            row.setText(String.format(Locale.getDefault(),
                    "%d  •  %s  (%d آية)", surah.number, surah.name, surah.count));
            row.setTextSize(18);
            row.setTextDirection(View.TEXT_DIRECTION_ANY_RTL);
            row.setPadding(24, 28, 24, 28);
            row.setOnClickListener(v -> {
                Intent intent = new Intent(this, QuranReaderActivity.class);
                intent.putExtra("page", surah.startPage);
                startActivity(intent);
            });
            list.addView(row);
        }
    }

    private void renderError() {
        TextView error = new TextView(this);
        error.setText("تعذر تحميل المصحف المحلي. أعد بناء التطبيق لإعادة توليد بيانات القرآن.");
        error.setTextSize(18);
        error.setPadding(24, 40, 24, 40);
        list.removeAllViews();
        list.addView(error);
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

    private static class SurahItem {
        final int number;
        final String name;
        final int count;
        final int startPage;
        SurahItem(int number, String name, int count, int startPage) {
            this.number = number;
            this.name = name;
            this.count = count;
            this.startPage = startPage;
        }
    }
}
