import '../entities/pitch_entity.dart';
import '../entities/review_entity.dart';

abstract class PitchRepository {
  Future<PitchEntity> getPitchById(String id);
  Future<List<ReviewEntity>> getReviewsByPitch(String id);
  Future<List<PitchEntity>> getPitchesByProviderAddressId(String providerAddressId);
  Future<PitchEntity> createPitch(Map<String, dynamic> data);
  Future<PitchEntity> updatePitch(String pitchId, Map<String, dynamic> data);
  Future<void> deletePitch(String pitchId);
}
