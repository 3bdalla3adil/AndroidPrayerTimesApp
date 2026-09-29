import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class QuranReaderScreen extends StatelessWidget {
  const QuranReaderScreen({super.key, required this.surahNumber});

  final int surahNumber;

  @override
  Widget build(BuildContext context) {
    final surahName = quran.getSurahName(surahNumber);
    final surahNameArabic = quran.getSurahNameArabic(surahNumber);
    final verseCount = quran.getVerseCount(surahNumber);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(surahName),
            Text(
              surahNameArabic,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: verseCount,
        itemBuilder: (context, index) {
          final verseNumber = index + 1;
          final arabic = quran.getVerse(surahNumber, verseNumber);
          final translation = quran.getVerseTranslation(
            surahNumber,
            verseNumber,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 14,
                    child: Text(
                      '$verseNumber',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  arabic,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 24, height: 1.8),
                ),
                const SizedBox(height: 8),
                Text(
                  translation,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
