import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  @override
  Widget build(BuildContext context) {
    // quran.surahList is a List<int> of surah numbers: [1, 2, 3, ..., 114]
    final surahNumbers = quran.surahList;

    return Scaffold(
      appBar: AppBar(title: const Text('Quran')),
      body: ListView.separated(
        itemCount: surahNumbers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final surahNumber = surahNumbers[index];
          final name = quran.getSurahName(surahNumber);
          final nameArabic = quran.getSurahNameArabic(surahNumber);
          final verseCount = quran.getVerseCount(surahNumber);
          final place = quran.getPlaceOfRevelation(surahNumber);

          return ListTile(
            leading: CircleAvatar(
              child: Text('$surahNumber'),
            ),
            title: Text('$name  —  $nameArabic'),
            subtitle: Text('$place • $verseCount verses'),
            onTap: () {
              // TODO: navigate to a surah reader screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _SurahReaderScreen(surahNumber: surahNumber),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SurahReaderScreen extends StatelessWidget {
  const _SurahReaderScreen({required this.surahNumber});

  final int surahNumber;

  @override
  Widget build(BuildContext context) {
    final verseCount = quran.getVerseCount(surahNumber);
    final surahName = quran.getSurahName(surahNumber);

    return Scaffold(
      appBar: AppBar(title: Text(surahName)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(
                        '$verseNumber',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
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
