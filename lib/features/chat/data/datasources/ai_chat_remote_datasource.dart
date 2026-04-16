import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AIChatRemoteDatasource {
  final DioClient dioClient;

  AIChatRemoteDatasource(this.dioClient);

  Future<Map<String, dynamic>> sendMessage(
      String userInput, String sessionId) async {
    final response = await dioClient.dio.post(
      ApiConstants.aiChat,
      data: {'userInput': userInput, 'sessionId': sessionId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendImage(
      String base64Image, String sessionId) async {
    final response = await dioClient.dio.post(
      ApiConstants.aiImage,
      data: {'image': base64Image, 'sessionId': sessionId},
    );
    return response.data as Map<String, dynamic>;
  }
}
