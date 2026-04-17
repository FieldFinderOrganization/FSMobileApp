import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/user_chat_remote_datasource.dart';
import '../../data/models/conversation_model.dart';

part 'conversation_list_state.dart';

class ConversationListCubit extends Cubit<ConversationListState> {
  final UserChatRemoteDatasource _datasource;
  String? _userId;

  ConversationListCubit({required UserChatRemoteDatasource datasource})
      : _datasource = datasource,
        super(const ConversationListInitial());

  Future<void> load(String userId) async {
    _userId = userId;
    emit(const ConversationListLoading());
    try {
      final conversations = await _datasource.getConversations(userId);
      emit(ConversationListLoaded(conversations));
    } catch (e) {
      emit(ConversationListError(e.toString()));
    }
  }

  Future<void> refresh() async {
    if (_userId == null) return;
    try {
      final conversations = await _datasource.getConversations(_userId!);
      emit(ConversationListLoaded(conversations));
    } catch (e) {
      emit(ConversationListError(e.toString()));
    }
  }

  void markConversationRead(String otherUserId) {
    final current = state;
    if (current is! ConversationListLoaded) return;
    final updated = current.conversations.map((c) {
      if (c.otherUserId == otherUserId) {
        return ConversationModel(
          otherUserId: c.otherUserId,
          otherUserName: c.otherUserName,
          otherUserImageUrl: c.otherUserImageUrl,
          lastMessage: c.lastMessage,
          lastMessageTime: c.lastMessageTime,
          isLastMessageFromMe: c.isLastMessageFromMe,
          unreadCount: 0,
        );
      }
      return c;
    }).toList();
    emit(ConversationListLoaded(updated));
  }
}
