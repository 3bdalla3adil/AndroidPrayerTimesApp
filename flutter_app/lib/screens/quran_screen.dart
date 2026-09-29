import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import 'quran_reader_screen.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = quran.totalSurahCount; // 114

    return Scaffold(
      appBar: AppBar(title: const Text('Quran')),
      body: ListView.separated(
        itemCount: total,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final surahNumber = index + 1;
          final name = quran.getSurahName(surahNumber);
          final nameArabic = quran.getSurahNameArabic(surahNumber);
          final verseCount = quran.getVerseCount(surahNumber);
          final place = quran.getPlaceOfRevelation(surahNumber);

          return ListTile(
            leading: CircleAvatar(child: Text('$surahNumber')),
            title: Text('$name  —  $nameArabic'),
            subtitle: Text('$place • $verseCount verses'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      QuranReaderScreen(surahNumber: surahNumber),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
