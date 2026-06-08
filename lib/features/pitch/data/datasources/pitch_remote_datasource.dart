import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/pitch_model.dart';

class PitchRemoteDatasource {
  final Dio _dio;

  PitchRemoteDatasource(this._dio);

  Future<PitchModel> fetchPitchById(String id) async {
    final response = await _dio.get('${ApiConstants.pitches}/$id');
    return PitchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PitchModel>> fetchPitchesByProviderAddressId(
    String providerAddressId,
  ) async {
    final response = await _dio.get(
      '${ApiConstants.pitches}/provider/$providerAddressId',
    );
    final list = response.data as List;
    return list
        .map((e) => PitchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PitchModel> createPitch(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.pitches, data: data);
    return PitchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PitchModel> updatePitch(
    String pitchId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put(
      '${ApiConstants.pitches}/$pitchId',
      data: data,
    );
    return PitchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePitch(String pitchId) async {
    await _dio.delete('${ApiConstants.pitches}/$pitchId');
  }

  /// Tuyến đường user→sân từ OSRM (qua BE). null nếu sân chưa có toạ độ hoặc OSRM tắt/lỗi.
  /// Trả {geometry: polyline encoded, distanceMeters, durationSeconds}.
  Future<Map<String, dynamic>?> fetchPitchRoute(
    String pitchId, {
    required double fromLat,
    required double fromLng,
  }) async {
    final res = await _dio.get(
      ApiConstants.pitchRoute(pitchId),
      queryParameters: {'fromLat': fromLat, 'fromLng': fromLng},
    );
    if (res.statusCode == 204 || res.data == null) return null;
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, List<PitchModel>>> fetchSuggested(
    String pitchId, {
    double? lat,
    double? lng,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.pitches}/$pitchId/suggested',
      queryParameters: {'lat': ?lat, 'lng': ?lng, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    List<PitchModel> parse(String key) {
      final list = data[key] as List?;
      if (list == null) return [];
      return list
          .map((e) => PitchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return {
      'nearby': parse('nearby'),
      'topRated': parse('topRated'),
      'visited': parse('visited'),
    };
  }

  Future<Map<String, List<PitchModel>>> fetchSuggestedForProduct({
    double? lat,
    double? lng,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.suggestedPitchesForProduct,
      queryParameters: {'lat': ?lat, 'lng': ?lng, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    List<PitchModel> parse(String key) {
      final list = data[key] as List?;
      if (list == null) return [];
      return list
          .map((e) => PitchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return {
      'nearby': parse('nearby'),
      'topRated': parse('topRated'),
      'visited': parse('visited'),
    };
  }
}
