import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../datasources/favorite_remote_datasource.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteRemoteDataSource remoteDataSource;

  FavoriteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<String>> getFavoriteIds() => remoteDataSource.getFavoriteIds();

  @override
  Future<List<PitchEntity>> getFavoritePitches() =>
      remoteDataSource.getFavoritePitches();

  @override
  Future<void> add(String pitchId) => remoteDataSource.add(pitchId);

  @override
  Future<void> remove(String pitchId) => remoteDataSource.remove(pitchId);
}
