import '../../../pitch/domain/entities/pitch_entity.dart';

abstract class FavoriteRepository {
  Future<List<String>> getFavoriteIds();
  Future<List<PitchEntity>> getFavoritePitches();
  Future<void> add(String pitchId);
  Future<void> remove(String pitchId);
}
