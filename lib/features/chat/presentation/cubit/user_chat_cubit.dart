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
    // Ignore messages not in this conversation
    if (msg.senderId != otherUserId && msg.senderId != currentUserId) return;
    final s = state as UserChatLoaded;
    emit(s.copyWith(messages: [...s.messages, msg]));
    if (msg.senderId == otherUserId) {
      remoteDatasource.markRead(
        senderId: otherUserId,
        receiverId: currentUserId,
      ).catchError((_) {});
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

  void closeChat() {
    wsService.disconnect();
  }

  @override
  Future<void> close() {
    wsService.disconnect();
    return super.close();
  }
}
