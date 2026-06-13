import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';

enum NotificationStatus { initial, loading, loaded, error }

/// Event realtime vừa nhận từ socket — dùng cho banner in-app.
/// Bọc trong object riêng để mỗi lần emit là instance mới (Bloc không nuốt
/// event trùng nội dung).
class RealtimeNotificationEvent {
  final String type;
  final String title;
  final String body;
  final String? refType;
  final String? refId;

  const RealtimeNotificationEvent({
    required this.type,
    required this.title,
    required this.body,
    this.refType,
    this.refId,
  });

  factory RealtimeNotificationEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeNotificationEvent(
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      refType: json['refType'] as String?,
      refId: json['refId'] as String?,
    );
  }
}

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationModel> items;
  final int unreadCount;
  final bool hasMore;
  final int page;
  final RealtimeNotificationEvent? lastRealtimeEvent;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.items = const [],
    this.unreadCount = 0,
    this.hasMore = false,
    this.page = 0,
    this.lastRealtimeEvent,
  });

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationModel>? items,
    int? unreadCount,
    bool? hasMore,
    int? page,
    RealtimeNotificationEvent? lastRealtimeEvent,
    bool clearRealtimeEvent = false,
  }) {
    return NotificationState(
      status: status ?? this.status,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      lastRealtimeEvent: clearRealtimeEvent
          ? null
          : (lastRealtimeEvent ?? this.lastRealtimeEvent),
    );
  }

  @override
  List<Object?> get props =>
      [status, items, unreadCount, hasMore, page, lastRealtimeEvent];
}
