class ConversationModel {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImageUrl;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final bool isLastMessageFromMe;
  final int unreadCount;

  const ConversationModel({
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImageUrl,
    required this.lastMessage,
    this.lastMessageTime,
    required this.isLastMessageFromMe,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    DateTime? time;
    final raw = json['lastMessageTime'];
    if (raw != null) {
      if (raw is int) {
        time = DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
      } else if (raw is String) {
        final normalized = (raw.endsWith('Z') || raw.contains('+') || raw.contains('-', 10))
            ? raw
            : '${raw}Z';
        time = DateTime.tryParse(normalized)?.toLocal();
      }
    }
    return ConversationModel(
      otherUserId: json['otherUserId'] as String? ?? '',
      otherUserName: json['otherUserName'] as String? ?? '',
      otherUserImageUrl: json['otherUserImageUrl'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: time,
      isLastMessageFromMe: json['isLastMessageFromMe'] as bool? ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
