# Quran reciters

The Quran reader streams individual ayah recordings from EveryAyah using this URL format:

```
https://everyayah.com/data/{reciter-folder}/{surah-3-digits}{ayah-3-digits}.mp3
```

The picker currently includes 36 complete Hafs recitation folders. The original 14 options remain available, with 22 additional reciters added:

- Abdullah Basfar
- Abdullah Al-Matroud
- Abdullah Awad Al-Juhani
- Ali Al-Hudhaify
- Ali Jaber
- Ibrahim Al-Akhdar
- Khalid Al-Qahtani
- Khalifa Al-Tunaiji
- Mahmoud Ali Al-Banna
- Mohammad Al-Tablaway
- Muhammad Ayyoub
- Muhammad Jibreel
- Salah Al-Budair
- Salah Bukhatir
- Sahl Yassin
- Mustafa Ismail
- Ayman Sowaid
- Karim Mansoori
- Ahmed Neana
- Akram Al-Alaqimy
- Muhsin Al-Qasim
- Yaser Salamah

## Coverage policy

Only complete Hafs ayah-by-ayah folders belong in the current reciter picker. The reader advances through each ayah and across Mushaf page boundaries, so adding a partial or full-surah-only source as though it contained individual ayah files would cause broken playback.

**Alaa bin Ibrahim Al-Muzajaji** currently has 11 recorded surahs listed by Etilawa (1, 2, 3, 14, 35, 36, 42, 55, 56, 71 and 72). Those are full-surah recordings, not a complete EveryAyah per-ayah folder, so this source needs a separate partial-surah playback mode before it can be safely added to the in-reader reciter selector.

## Audio metadata and coverage references

- EveryAyah audio folder metadata: https://github.com/Mushaf-Learning/quran-audio
- Complete Hafs per-ayah reciter coverage reference: https://quranonlineread.com/quran/reciters/
- Alaa bin Ibrahim Al-Muzajaji's currently listed 11-surah collection: https://etilawa.com/en/reciters/alaa-bin-ibrahim-al-muzajaji/

The metadata repositories and coverage pages are references for folder names and availability; they do not grant redistribution rights to the hosted audio recordings. Audio is streamed from EveryAyah and is not bundled with this app.
