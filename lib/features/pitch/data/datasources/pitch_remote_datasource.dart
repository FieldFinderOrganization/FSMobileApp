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
}
