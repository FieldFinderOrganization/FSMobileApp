import 'dart:convert';
import 'chat_message_model.dart';

class ChatSessionModel {
  final String sessionId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessageModel> messages;

  const ChatSessionModel({
    required this.sessionId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  ChatSessionModel copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessageModel>? messages,
  }) =>
      ChatSessionModel(
        sessionId: sessionId,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        messages: messages ?? this.messages,
      );

  String get lastMessagePreview {
    if (messages.isEmpty) return '';
    final last = messages.last;
    if (last.isImage) return '🖼 Hình ảnh';
    return last.content.length > 50
        ? '${last.content.substring(0, 50)}...'
        : last.content;
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      ChatSessionModel(
        sessionId: json['sessionId'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        messages: (json['messages'] as List<dynamic>)
            .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
