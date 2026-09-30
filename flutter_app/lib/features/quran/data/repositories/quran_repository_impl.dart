import '../../../../core/result.dart';
import '../../domain/entities/quran_verse.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';

final class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl(this._local);

  final QuranLocalDataSource _local;

  @override
  Future<Result<List<QuranVerse>>> getSurah(int surahNumber) async {
    try {
      return Success(await _local.getSurah(surahNumber));
    } catch (error) {
      return Failure(error);
    }
  }

  @override
  Future<Result<List<QuranVerse>>> search(String query) async {
    try {
      return Success(await _local.search(query));
    } catch (error) {
      return Failure(error);
    }
  }

  @override
  Future<Result<QuranVerse>> getVerse(int surahNumber, int ayahNumber) async {
    try {
      return Success(await _local.getVerse(surahNumber, ayahNumber));
    } catch (error) {
      return Failure(error);
    }
  }
}
