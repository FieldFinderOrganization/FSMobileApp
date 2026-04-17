import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isUser ? 60 : 12,
          right: isUser ? 12 : 60,
        ),
        padding: message.isImage && isUser
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryRed : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (message.isImage && message.imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(message.imagePath!),
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
      );
    }

    return Text(
      message.content,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: message.isUser ? Colors.white : const Color(0xFF1F2937),
        height: 1.4,
      ),
    );
  }
}
