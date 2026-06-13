import '../entities/pitch_entity.dart';
import '../entities/review_entity.dart';
import '../entities/suggested_pitches_entity.dart';

abstract class PitchRepository {
  Future<PitchEntity> getPitchById(String id);
  Future<List<ReviewEntity>> getReviewsByPitch(String id);
  Future<List<PitchEntity>> getPitchesByProviderAddressId(String providerAddressId);
  Future<PitchEntity> createPitch(Map<String, dynamic> data);
  Future<PitchEntity> updatePitch(String pitchId, Map<String, dynamic> data);
  Future<void> deletePitch(String pitchId);
  Future<void> deactivatePitch(String pitchId, DateTime targetDate);
  Future<void> reactivatePitch(String pitchId);
  Future<SuggestedPitchesEntity> getSuggested(String pitchId, {double? lat, double? lng, int limit = 10});
  Future<SuggestedPitchesEntity> getSuggestedForProduct({double? lat, double? lng, int limit = 10});
}
