import 'dart:convert';

class ChatMessageModel {
  final String id;
  final String content;
  final bool isUser;
  final bool isImage;
  final String? imagePath; // local file path (ảnh user gửi)
  final DateTime createdAt;
  final Map<String, dynamic>? aiData;

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.isImage,
    this.imagePath,
    required this.createdAt,
    this.aiData,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'isImage': isImage,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
        'aiData': aiData != null ? jsonEncode(aiData) : null,
      };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String,
        content: json['content'] as String,
        isUser: json['isUser'] as bool,
        isImage: json['isImage'] as bool,
        imagePath: json['imagePath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        aiData: json['aiData'] != null
            ? jsonDecode(json['aiData'] as String) as Map<String, dynamic>
            : null,
      );
}
