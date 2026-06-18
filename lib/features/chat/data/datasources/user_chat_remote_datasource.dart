import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/conversation_model.dart';
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

  /// Hội thoại với peer có bị khóa nhắn tin không (đơn shipper đã hoàn tất/hủy).
  Future<bool> getChatLockStatus({
    required String userId,
    required String peerId,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.chatLockStatus,
        queryParameters: {'userId': userId, 'peerId': peerId},
      );
      return response.data['locked'] == true;
    } catch (_) {
      return false; // lỗi mạng -> không khóa nhầm
    }
  }

  Future<DateTime?> getUserLastLogin(String userId) async {
    try {
      final response = await dioClient.dio.get(ApiConstants.userById(userId));
      // Ưu tiên lastSeenAt (mốc rời WS thật); fallback lastLoginAt cho acc chưa có presence.
      final raw = response.data['lastSeenAt'] ?? response.data['lastLoginAt'];
      if (raw == null) return null;
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
      final normalized = raw.toString().endsWith('Z') || raw.toString().contains('+')
          ? raw.toString()
          : '${raw}Z';
      return DateTime.tryParse(normalized)?.toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<String> uploadChatImage({
    required File file,
    required String senderId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'senderId': senderId,
      });
      final response = await dioClient.dio.post(
        ApiConstants.chatUploadImage,
        data: formData,
      );
      return response.data['imageUrl'] as String;
    } on DioException {
      rethrow;
    }
  }

  Future<String> uploadChatVideo({
    required File file,
    required String senderId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'senderId': senderId,
      });
      final response = await dioClient.dio.post(
        ApiConstants.chatUploadVideo,
        data: formData,
      );
      return response.data['videoUrl'] as String;
    } on DioException {
      rethrow;
    }
  }

  Future<void> reactToMessage({
    required String messageId,
    required String reactorId,
    String? emoji,
  }) async {
    try {
      await dioClient.dio.post(
        ApiConstants.chatReaction(messageId),
        queryParameters: {
          'reactorId': reactorId,
          if (emoji != null && emoji.isNotEmpty) 'emoji': emoji,
        },
      );
    } on DioException {
      rethrow;
    }
  }

  Future<List<ConversationModel>> getConversations(String userId) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.chatConversations,
        queryParameters: {'userId': userId},
      );
      final List<dynamic> items = response.data is List ? response.data : [];
      return items.map((e) => ConversationModel.fromJson(e)).toList();
    } on DioException {
      rethrow;
    }
  }
}
