import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/user_chat_remote_datasource.dart';
import '../../data/datasources/user_chat_websocket_service.dart';
import '../../data/models/user_chat_message_model.dart';

abstract class UserChatState extends Equatable {
  const UserChatState();
  @override
  List<Object?> get props => [];
}

class UserChatInitial extends UserChatState {}

class UserChatLoading extends UserChatState {}

class UserChatLoaded extends UserChatState {
  final List<UserChatMessageModel> messages;
  final bool isConnected;
  final bool isSending;

  const UserChatLoaded({
    required this.messages,
    this.isConnected = false,
    this.isSending = false,
  });

  UserChatLoaded copyWith({
    List<UserChatMessageModel>? messages,
    bool? isConnected,
    bool? isSending,
  }) {
    return UserChatLoaded(
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [messages, isConnected, isSending];
}

class UserChatError extends UserChatState {
  final String message;
  const UserChatError(this.message);
  @override
  List<Object?> get props => [message];
}

class UserChatCubit extends Cubit<UserChatState> {
  final UserChatRemoteDatasource remoteDatasource;
  final UserChatWebSocketService wsService;
  final String currentUserId;
  final String otherUserId;

  // Queue for messages sent before WS is connected
  final List<String> _pendingMessages = [];

  /// Báo lên UI khi server khóa hội thoại (đơn hoàn tất) — UI chuyển sang chỉ đọc.
  void Function(String message)? onLocked;

  UserChatCubit({
    required this.remoteDatasource,
    required this.wsService,
    required this.currentUserId,
    required this.otherUserId,
  }) : super(UserChatInitial());

  Future<void> initChat() async {
    emit(UserChatLoading());
    try {
      final history = await remoteDatasource.getChatHistory(
        userId1: currentUserId,
        userId2: otherUserId,
      );
      history.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      // Mark read in background — don't let failure block chat
      remoteDatasource.markRead(
        senderId: otherUserId,
        receiverId: currentUserId,
      ).catchError((_) {});

      emit(UserChatLoaded(messages: history, isConnected: false));

      await wsService.connect(
        receiverId: currentUserId,
        onMessage: _onIncomingMessage,
        onReaction: applyReaction,
        onLocked: (msg) => onLocked?.call(msg),
        onConnected: () {
          if (state is UserChatLoaded) {
            emit((state as UserChatLoaded).copyWith(isConnected: true));
          }
          // Flush pending messages queued before connection was ready
          for (final content in List<String>.from(_pendingMessages)) {
            wsService.sendMessage(
              senderId: currentUserId,
              receiverId: otherUserId,
              content: content,
            );
          }
          _pendingMessages.clear();
        },
        onError: (err) {
          if (state is UserChatLoaded) {
            emit((state as UserChatLoaded).copyWith(isConnected: false));
          }
        },
      );
    } catch (e) {
      emit(UserChatError(e.toString()));
    }
  }

  void _onIncomingMessage(UserChatMessageModel msg) {
    if (state is! UserChatLoaded) return;
    if (msg.senderId != otherUserId && msg.senderId != currentUserId) return;
    final s = state as UserChatLoaded;

    if (msg.senderId == currentUserId) {
      // Echo từ server cho tin của chính mình: thay optimistic message
      // (id giả) bằng bản có UUID thật để reaction match được theo id.
      final idx = s.messages.indexWhere((m) =>
          !m.hasServerId &&
          m.senderId == currentUserId &&
          m.type == msg.type &&
          (msg.isImage || msg.isVideo
              ? m.imageUrl == msg.imageUrl
              : m.content == msg.content));
      if (idx >= 0) {
        final updated = [...s.messages];
        updated[idx] = msg;
        emit(s.copyWith(messages: updated));
      }
      // Không tìm thấy optimistic → đã được replace trước đó, bỏ qua tránh duplicate
      return;
    }

    emit(s.copyWith(messages: [...s.messages, msg]));
    remoteDatasource.markRead(
      senderId: otherUserId,
      receiverId: currentUserId,
    ).catchError((_) {});
  }

  /// Reaction realtime từ người kia (qua WS) — cập nhật message tương ứng.
  void applyReaction(String messageId, String? reaction) {
    if (state is! UserChatLoaded) return;
    final s = state as UserChatLoaded;
    final idx = s.messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    final updated = [...s.messages];
    updated[idx] = updated[idx].copyWith(
      reaction: reaction,
      clearReaction: reaction == null,
    );
    emit(s.copyWith(messages: updated));
  }

  /// Thả/gỡ reaction vào tin nhắn của người kia. Tap lại emoji đang chọn = gỡ.
  Future<void> reactToMessage(UserChatMessageModel msg, String emoji) async {
    if (state is! UserChatLoaded) return;
    if (msg.senderId != otherUserId || !msg.hasServerId) return;
    final previous = msg.reaction;
    final next = previous == emoji ? null : emoji;

    applyReaction(msg.id, next); // optimistic
    try {
      await remoteDatasource.reactToMessage(
        messageId: msg.id,
        reactorId: currentUserId,
        emoji: next,
      );
    } catch (_) {
      applyReaction(msg.id, previous); // revert
    }
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty) return;
    if (state is! UserChatLoaded) return;
    final s = state as UserChatLoaded;
    final trimmed = content.trim();

    // Optimistic update
    final optimistic = UserChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      receiverId: otherUserId,
      content: trimmed,
      sentAt: DateTime.now(),
      isRead: false,
    );
    emit(s.copyWith(messages: [...s.messages, optimistic]));

    if (wsService.isConnected) {
      wsService.sendMessage(
        senderId: currentUserId,
        receiverId: otherUserId,
        content: trimmed,
      );
    } else {
      // Queue and retry when connection is ready
      _pendingMessages.add(trimmed);
    }
  }

  Future<void> sendImage(File imageFile) async {
    if (state is! UserChatLoaded) return;
    final s = state as UserChatLoaded;

    final optimisticId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimistic = UserChatMessageModel(
      id: optimisticId,
      senderId: currentUserId,
      receiverId: otherUserId,
      content: '',
      imageUrl: imageFile.path,
      type: 'IMAGE',
      sentAt: DateTime.now(),
      isRead: false,
    );
    emit(s.copyWith(messages: [...s.messages, optimistic], isSending: true));

    try {
      final imageUrl = await remoteDatasource.uploadChatImage(
        file: imageFile,
        senderId: currentUserId,
      );

      // Replace optimistic (local path) bằng Cloudinary URL để tắt spinner
      if (state is UserChatLoaded) {
        final current = state as UserChatLoaded;
        final confirmed = UserChatMessageModel(
          id: optimisticId,
          senderId: currentUserId,
          receiverId: otherUserId,
          content: '',
          imageUrl: imageUrl,
          type: 'IMAGE',
          sentAt: optimistic.sentAt,
          isRead: false,
        );
        emit(current.copyWith(
          messages: current.messages
              .map((m) => m.id == optimisticId ? confirmed : m)
              .toList(),
          isSending: false,
        ));
      }

      if (wsService.isConnected) {
        wsService.sendMessage(
          senderId: currentUserId,
          receiverId: otherUserId,
          content: '',
          type: 'IMAGE',
          imageUrl: imageUrl,
        );
      }
    } catch (_) {
      if (state is UserChatLoaded) {
        final current = state as UserChatLoaded;
        emit(current.copyWith(
          messages: current.messages.where((m) => m.id != optimisticId).toList(),
          isSending: false,
        ));
      }
    }
  }

  /// Trả về false nếu video vượt giới hạn dung lượng (không gửi).
  Future<bool> sendVideo(File videoFile) async {
    if (state is! UserChatLoaded) return true;

    // Khớp giới hạn multipart 50MB của backend
    const maxBytes = 50 * 1024 * 1024;
    if (await videoFile.length() > maxBytes) return false;

    final s = state as UserChatLoaded;
    final optimisticId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimistic = UserChatMessageModel(
      id: optimisticId,
      senderId: currentUserId,
      receiverId: otherUserId,
      content: '',
      imageUrl: videoFile.path,
      type: 'VIDEO',
      sentAt: DateTime.now(),
      isRead: false,
    );
    emit(s.copyWith(messages: [...s.messages, optimistic], isSending: true));

    try {
      final videoUrl = await remoteDatasource.uploadChatVideo(
        file: videoFile,
        senderId: currentUserId,
      );

      if (state is UserChatLoaded) {
        final current = state as UserChatLoaded;
        emit(current.copyWith(
          messages: current.messages
              .map((m) =>
                  m.id == optimisticId ? m.copyWith(imageUrl: videoUrl) : m)
              .toList(),
          isSending: false,
        ));
      }

      if (wsService.isConnected) {
        wsService.sendMessage(
          senderId: currentUserId,
          receiverId: otherUserId,
          content: '',
          type: 'VIDEO',
          imageUrl: videoUrl,
        );
      }
      return true;
    } catch (_) {
      if (state is UserChatLoaded) {
        final current = state as UserChatLoaded;
        emit(current.copyWith(
          messages: current.messages.where((m) => m.id != optimisticId).toList(),
          isSending: false,
        ));
      }
      return false;
    }
  }

  void closeChat() {
    wsService.disconnect();
  }

  @override
  Future<void> close() {
    wsService.disconnect();
    return super.close();
  }
}
