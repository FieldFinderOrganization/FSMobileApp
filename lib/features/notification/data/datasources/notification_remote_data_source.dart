import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final DioClient dioClient;

  const NotificationRemoteDataSource({required this.dioClient});

  /// Trả về (items, hasMore) — BE trả Page<NotificationDTO>.
  Future<(List<NotificationModel>, bool)> fetchNotifications({
    int page = 0,
    int size = 20,
  }) async {
    final response = await dioClient.dio.get(
      '/notifications',
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data as Map<String, dynamic>;
    final content = (data['content'] as List<dynamic>? ?? [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    // BE bật @EnableSpringDataWebSupport(VIA_DTO): Page trả về dạng
    // {content, page: {number, totalPages, ...}} — không có field "last".
    final pageInfo = data['page'] as Map<String, dynamic>?;
    final number = (pageInfo?['number'] as num?)?.toInt() ?? 0;
    final totalPages = (pageInfo?['totalPages'] as num?)?.toInt() ?? 1;
    return (content, number + 1 < totalPages);
  }

  Future<int> fetchUnreadCount() async {
    final response = await dioClient.dio.get('/notifications/unread-count');
    return (response.data as num).toInt();
  }

  Future<void> markRead(String id) async {
    await dioClient.dio.post('/notifications/$id/mark-read');
  }

  Future<void> markAllRead() async {
    await dioClient.dio.post('/notifications/mark-all-read');
  }
}
