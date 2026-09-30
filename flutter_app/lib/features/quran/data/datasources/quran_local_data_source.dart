import '../../domain/entities/quran_verse.dart';

abstract interface class QuranLocalDataSource {
  Future<List<QuranVerse>> getSurah(int surahNumber);

  Future<List<QuranVerse>> search(String query);

  Future<QuranVerse> getVerse(int surahNumber, int ayahNumber);
}
