import '../entities/pitch_entity.dart';
import '../entities/review_entity.dart';

abstract class PitchRepository {
  Future<PitchEntity> getPitchById(String id);
  Future<List<ReviewEntity>> getReviewsByPitch(String id);
}
