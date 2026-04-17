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
    return UserChatMessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['read'] == true || json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'read': isRead,
    };
  }
}
