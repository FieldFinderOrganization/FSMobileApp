import '../../data/models/chat_session_model.dart';

abstract class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatSessionListLoaded extends ChatState {
  final List<ChatSessionModel> sessions;
  const ChatSessionListLoaded(this.sessions);
}

class ChatSessionOpen extends ChatState {
  final ChatSessionModel session;
  final bool isLoading;
  const ChatSessionOpen({required this.session, this.isLoading = false});

  ChatSessionOpen copyWith({ChatSessionModel? session, bool? isLoading}) =>
      ChatSessionOpen(
        session: session ?? this.session,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
}
