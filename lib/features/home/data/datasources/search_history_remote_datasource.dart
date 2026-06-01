import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/search_history_model.dart';

class SearchHistoryRemoteDatasource {
  final Dio _dio;

  SearchHistoryRemoteDatasource(this._dio);

  Future<List<SearchHistoryModel>> fetchHistory({int limit = 10}) async {
    final response = await _dio.get(
      ApiConstants.searchHistory,
      queryParameters: {'limit': limit},
    );
    final list = response.data as List;
    return list
        .map((e) => SearchHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SearchHistoryModel> upsert(String keyword) async {
    final response = await _dio.post(
      ApiConstants.searchHistory,
      data: {'keyword': keyword},
    );
    return SearchHistoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${ApiConstants.searchHistory}/$id');
  }

  Future<void> clear() async {
    await _dio.delete(ApiConstants.searchHistory);
  }
}
