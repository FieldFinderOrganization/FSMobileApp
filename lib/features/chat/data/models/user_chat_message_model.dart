class UserChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  const UserChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    required this.isRead,
  });

  factory UserChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Backend field: messageId (UUID), timestamp (Date), isRead (Boolean)
    final rawTime = json['timestamp'] ?? json['sentAt'];
    DateTime sentAt;
    if (rawTime is int) {
      sentAt = DateTime.fromMillisecondsSinceEpoch(rawTime).toLocal();
    } else if (rawTime != null) {
      final str = rawTime.toString();
      // Nếu không có timezone suffix → coi là UTC rồi convert sang local
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
      sentAt: sentAt,
      isRead: json['isRead'] == true || json['read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
    };
  }
}
