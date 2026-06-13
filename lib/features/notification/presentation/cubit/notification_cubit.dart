import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/datasources/notification_websocket_service.dart';
import '../../data/models/notification_model.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationWebSocketService webSocketService;

  static const _pageSize = 20;

  NotificationCubit({
    required this.remoteDataSource,
    required this.webSocketService,
  }) : super(const NotificationState());

  /// Gọi sau login (MainShell initState): fetch badge + mở socket toàn cục.
  Future<void> start(String userId) async {
    try {
      final count = await remoteDataSource.fetchUnreadCount();
      emit(state.copyWith(unreadCount: count));
    } catch (_) {}

    await webSocketService.connect(userId: userId, onEvent: _onRealtimeEvent);
  }

  void _onRealtimeEvent(Map<String, dynamic> json) {
    final event = RealtimeNotificationEvent.fromJson(json);

    if (event.type == 'CHAT_MESSAGE') {
      // Chat = realtime-only, không lưu DB → chỉ banner, không đổi badge chuông
      emit(state.copyWith(lastRealtimeEvent: event));
      return;
    }

    // Notification có lưu DB: prepend vào list (nếu đã load) + tăng badge
    final item = NotificationModel.fromJson(json);
    emit(state.copyWith(
      unreadCount: state.unreadCount + 1,
      items: state.status == NotificationStatus.loaded
          ? [item, ...state.items]
          : state.items,
      lastRealtimeEvent: event,
    ));
  }

  /// Banner đã hiển thị xong — xóa để không hiện lại khi rebuild.
  void consumeRealtimeEvent() {
    emit(state.copyWith(clearRealtimeEvent: true));
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (state.status == NotificationStatus.loading) return;
    final page = refresh ? 0 : state.page;
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      final (items, hasMore) =
          await remoteDataSource.fetchNotifications(page: page, size: _pageSize);
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        items: page == 0 ? items : [...state.items, ...items],
        hasMore: hasMore,
        page: page + 1,
      ));
    } catch (_) {
      emit(state.copyWith(status: NotificationStatus.error));
    }
  }

  Future<void> markRead(NotificationModel item) async {
    if (item.isRead) return;
    emit(state.copyWith(
      items: state.items
          .map((n) => n.id == item.id ? n.copyWith(isRead: true) : n)
          .toList(),
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    ));
    try {
      await remoteDataSource.markRead(item.id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    emit(state.copyWith(
      items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    ));
    try {
      await remoteDataSource.markAllRead();
    } catch (_) {}
  }

  /// Gọi khi logout — ngắt socket, reset badge.
  void stop() {
    webSocketService.disconnect();
    emit(const NotificationState());
  }

  @override
  Future<void> close() {
    webSocketService.disconnect();
    return super.close();
  }
}
