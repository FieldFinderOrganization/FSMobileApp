import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/pitch_repository.dart';
import '../datasources/pitch_remote_datasource.dart';
import '../datasources/review_remote_datasource.dart';

class PitchRepositoryImpl implements PitchRepository {
  final PitchRemoteDatasource pitchRemoteDatasource;
  final ReviewRemoteDatasource reviewRemoteDatasource;

  PitchRepositoryImpl({
    required this.pitchRemoteDatasource,
    required this.reviewRemoteDatasource,
  });

  @override
  Future<PitchEntity> getPitchById(String id) async {
    return await pitchRemoteDatasource.fetchPitchById(id);
  }

  @override
  Future<List<ReviewEntity>> getReviewsByPitch(String id) async {
    return await reviewRemoteDatasource.fetchReviewsByPitch(id);
  }
}
