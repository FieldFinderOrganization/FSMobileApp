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

  @override
  Future<List<PitchEntity>> getPitchesByProviderAddressId(String providerAddressId) async {
    return await pitchRemoteDatasource.fetchPitchesByProviderAddressId(providerAddressId);
  }

  @override
  Future<PitchEntity> createPitch(Map<String, dynamic> data) async {
    return await pitchRemoteDatasource.createPitch(data);
  }

  @override
  Future<PitchEntity> updatePitch(String pitchId, Map<String, dynamic> data) async {
    return await pitchRemoteDatasource.updatePitch(pitchId, data);
  }

  @override
  Future<void> deletePitch(String pitchId) async {
    await pitchRemoteDatasource.deletePitch(pitchId);
  }
}
