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

      await remoteDatasource.markRead(
        senderId: otherUserId,
        receiverId: currentUserId,
      );

      emit(UserChatLoaded(messages: history, isConnected: false));

      await wsService.connect(
        receiverId: currentUserId,
        onMessage: _onIncomingMessage,
        onConnected: () {
          if (state is UserChatLoaded) {
            emit((state as UserChatLoaded).copyWith(isConnected: true));
          }
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
    emit(s.copyWith(messages: [...s.messages, msg]));
    if (msg.senderId == otherUserId) {
      remoteDatasource.markRead(
        senderId: otherUserId,
        receiverId: currentUserId,
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (state is! UserChatLoaded) return;
    final s = state as UserChatLoaded;

    emit(s.copyWith(isSending: true));

    final optimistic = UserChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      receiverId: otherUserId,
      content: content.trim(),
      sentAt: DateTime.now(),
      isRead: false,
    );

    emit(s.copyWith(
      messages: [...s.messages, optimistic],
      isSending: false,
    ));

    wsService.sendMessage(
      senderId: currentUserId,
      receiverId: otherUserId,
      content: content.trim(),
    );
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
