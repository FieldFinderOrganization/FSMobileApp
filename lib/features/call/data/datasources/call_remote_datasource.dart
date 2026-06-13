import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

class CallRemoteDatasource {
  final DioClient dioClient;

  const CallRemoteDatasource({required this.dioClient});

  /// Lấy danh sách ICE server (STUN + TURN credential ngắn hạn) từ BE.
  /// Fallback STUN công khai nếu BE lỗi để cuộc gọi vẫn chạy trên cùng mạng.
  Future<List<Map<String, dynamic>>> fetchIceServers(String userId) async {
    try {
      final res = await dioClient.dio.get(ApiConstants.callIceConfig(userId));
      final data = res.data as Map<String, dynamic>;
      final servers = (data['iceServers'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (servers.isNotEmpty) return servers;
    } catch (_) {}
    return [
      {'urls': 'stun:stun.l.google.com:19302'},
    ];
  }

  /// Lưu kết quả cuộc gọi (chỉ caller gọi) → BE tạo ChatMessage type=CALL.
  Future<void> logCall({
    required String senderId,
    required String receiverId,
    required String status, // ANSWERED | MISSED | REJECTED | CANCELED
    int durationSec = 0,
    String media = 'AUDIO',
  }) async {
    await dioClient.dio.post(ApiConstants.callLog, data: {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'durationSec': durationSec,
      'media': media,
    });
  }
}
