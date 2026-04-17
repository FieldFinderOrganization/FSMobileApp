import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_chat_message_model.dart';

class UserChatRemoteDatasource {
  final DioClient dioClient;

  UserChatRemoteDatasource({required this.dioClient});

  Future<List<UserChatMessageModel>> getChatHistory({
    required String userId1,
    required String userId2,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.chatHistory,
        queryParameters: {
          'user1': userId1,
          'user2': userId2,
          'page': page,
          'size': size,
        },
      );
      final data = response.data;
      final List<dynamic> items =
          data is List ? data : (data['content'] ?? data['messages'] ?? []);
      return items.map((e) => UserChatMessageModel.fromJson(e)).toList();
    } on DioException {
      rethrow;
    }
  }

  Future<void> markRead({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      await dioClient.dio.post(
        ApiConstants.chatMarkRead,
        queryParameters: {
          'senderId': senderId,
          'receiverId': receiverId,
        },
      );
    } on DioException {
      rethrow;
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.chatUnreadCount,
        queryParameters: {'userId': userId},
      );
      return (response.data as num?)?.toInt() ?? 0;
    } on DioException {
      rethrow;
    }
  }
}
