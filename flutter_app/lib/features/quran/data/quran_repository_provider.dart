import 'data/datasources/quran_package_data_source.dart';
import 'data/repositories/quran_repository_impl.dart';
import 'domain/repositories/quran_repository.dart';

QuranRepository createQuranRepository() {
  return QuranRepositoryImpl(QuranPackageDataSource());
}
