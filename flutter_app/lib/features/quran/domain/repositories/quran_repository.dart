import '../../../../core/result.dart';
import '../entities/quran_verse.dart';

abstract interface class QuranRepository {
  Future<Result<List<QuranVerse>>> getSurah(int surahNumber);

  Future<Result<List<QuranVerse>>> search(String query);

  Future<Result<QuranVerse>> getVerse(int surahNumber, int ayahNumber);
}
