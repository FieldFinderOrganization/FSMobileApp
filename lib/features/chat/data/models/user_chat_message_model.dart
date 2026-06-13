class UserChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? imageUrl; // media URL chung: ảnh hoặc video tùy type
  final String type; // 'TEXT' | 'IMAGE' | 'VIDEO' | 'CALL'
  final DateTime sentAt;
  final bool isRead;
  final String? reaction; // emoji người nhận thả vào tin nhắn này
  final String? callStatus; // ANSWERED | MISSED | REJECTED | CANCELED (khi type=CALL)
  final int? callDurationSec;

  const UserChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.imageUrl,
    this.type = 'TEXT',
    required this.sentAt,
    required this.isRead,
    this.reaction,
    this.callStatus,
    this.callDurationSec,
  });

  bool get isCall => type == 'CALL';

  bool get isImage =>
      type == 'IMAGE' ||
      (type != 'VIDEO' && type != 'CALL' && imageUrl != null && imageUrl!.isNotEmpty);

  bool get isVideo => type == 'VIDEO';

  /// Optimistic message dùng millisecondsSinceEpoch làm id; id từ server là UUID.
  bool get hasServerId => id.contains('-');

  UserChatMessageModel copyWith({
    String? id,
    String? content,
    String? imageUrl,
    String? type,
    DateTime? sentAt,
    bool? isRead,
    String? reaction,
    bool clearReaction = false,
    String? callStatus,
    int? callDurationSec,
  }) {
    return UserChatMessageModel(
      id: id ?? this.id,
      senderId: senderId,
      receiverId: receiverId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      reaction: clearReaction ? null : (reaction ?? this.reaction),
      callStatus: callStatus ?? this.callStatus,
      callDurationSec: callDurationSec ?? this.callDurationSec,
    );
  }

  factory UserChatMessageModel.fromJson(Map<String, dynamic> json) {
    final rawTime = json['timestamp'] ?? json['sentAt'];
    DateTime sentAt;
    if (rawTime is int) {
      sentAt = DateTime.fromMillisecondsSinceEpoch(rawTime).toLocal();
    } else if (rawTime != null) {
      final str = rawTime.toString();
      final normalized = (str.endsWith('Z') || str.contains('+') || str.contains('-', 10))
          ? str
          : '${str}Z';
      sentAt = (DateTime.tryParse(normalized) ?? DateTime.now()).toLocal();
    } else {
      sentAt = DateTime.now();
    }

    return UserChatMessageModel(
      id: (json['messageId'] ?? json['id'])?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl']?.toString(),
      type: json['type']?.toString() ?? 'TEXT',
      sentAt: sentAt,
      isRead: json['isRead'] == true || json['read'] == true,
      reaction: json['reaction']?.toString(),
      callStatus: json['callStatus']?.toString(),
      callDurationSec: (json['callDurationSec'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'type': type,
    };
  }
}
