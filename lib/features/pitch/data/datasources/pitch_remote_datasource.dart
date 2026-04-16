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

  Future<List<PitchModel>> fetchPitchesByProviderAddressId(String providerAddressId) async {
    final response = await _dio.get('${ApiConstants.pitches}/provider/$providerAddressId');
    final list = response.data as List;
    return list.map((e) => PitchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PitchModel> createPitch(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.pitches, data: data);
    return PitchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PitchModel> updatePitch(String pitchId, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.pitches}/$pitchId', data: data);
    return PitchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePitch(String pitchId) async {
    await _dio.delete('${ApiConstants.pitches}/$pitchId');
  }
}
