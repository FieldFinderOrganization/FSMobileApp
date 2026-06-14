import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../pitch/data/models/pitch_model.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';

/// Gọi API sân yêu thích. Tái dùng PitchModel.fromJson vì BE trả PitchResponseDTO
/// (cùng shape với /pitches).
class FavoriteRemoteDataSource {
  final DioClient dioClient;

  FavoriteRemoteDataSource({required this.dioClient});

  /// Danh sách pitchId đã yêu thích (mới nhất trước).
  Future<List<String>> getFavoriteIds() async {
    final response = await dioClient.dio.get(ApiConstants.favoritePitchIds);
    final list = response.data as List;
    return list.map((e) => e.toString()).toList();
  }

  /// Danh sách sân yêu thích đầy đủ.
  Future<List<PitchEntity>> getFavoritePitches() async {
    final response = await dioClient.dio.get(ApiConstants.favoritePitches);
    final list = response.data as List;
    return list
        .map((e) => PitchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(String pitchId) async {
    await dioClient.dio.post(ApiConstants.favoritePitch(pitchId));
  }

  Future<void> remove(String pitchId) async {
    await dioClient.dio.delete(ApiConstants.favoritePitch(pitchId));
  }
}
