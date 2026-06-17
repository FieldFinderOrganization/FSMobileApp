import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/user_chat_remote_datasource.dart';
import '../../data/models/conversation_model.dart';

part 'conversation_list_state.dart';

class ConversationListCubit extends Cubit<ConversationListState> {
  final UserChatRemoteDatasource _datasource;
  String? _userId;

  /// Full danh sách chưa lọc — dùng để filter phía client.
  List<ConversationModel> _allConversations = [];
  ConversationFilter _filter = ConversationFilter.all;

  ConversationListCubit({required UserChatRemoteDatasource datasource})
      : _datasource = datasource,
        super(const ConversationListInitial());

  Future<void> load(String userId) async {
    _userId = userId;
    emit(const ConversationListLoading());
    try {
      _allConversations = await _datasource.getConversations(userId);
      _emitFiltered();
    } catch (e) {
      emit(ConversationListError(e.toString()));
    }
  }

  Future<void> refresh() async {
    if (_userId == null) return;
    try {
      _allConversations = await _datasource.getConversations(_userId!);
      _emitFiltered();
    } catch (e) {
      emit(ConversationListError(e.toString()));
    }
  }

  /// Đổi filter (Tất cả / Chủ sân / Shipper).
  void setFilter(ConversationFilter filter) {
    _filter = filter;
    _emitFiltered();
  }

  void _emitFiltered() {
    final filtered = switch (_filter) {
      ConversationFilter.all => _allConversations,
      ConversationFilter.provider => _allConversations
          .where((c) => c.otherUserRole == 'PROVIDER')
          .toList(),
      ConversationFilter.shipper => _allConversations
          .where((c) => c.otherUserRole == 'SHIPPER')
          .toList(),
    };
    emit(ConversationListLoaded(filtered, activeFilter: _filter));
  }

  void markConversationRead(String otherUserId) {
    // Đánh dấu đã đọc trên server (tin của người kia → mình). Lỗi mạng không
    // được chặn UI; badge toàn cục sẽ được đồng bộ lại khi rời màn chat.
    final uid = _userId;
    if (uid != null) {
      _datasource
          .markRead(senderId: otherUserId, receiverId: uid)
          .catchError((_) {});
    }

    // Cập nhật cả _allConversations (source-of-truth) lẫn filtered list.
    _allConversations = _allConversations.map((c) {
      if (c.otherUserId == otherUserId) {
        return ConversationModel(
          otherUserId: c.otherUserId,
          otherUserName: c.otherUserName,
          otherUserImageUrl: c.otherUserImageUrl,
          otherUserRole: c.otherUserRole,
          lastMessage: c.lastMessage,
          lastMessageTime: c.lastMessageTime,
          isLastMessageFromMe: c.isLastMessageFromMe,
          unreadCount: 0,
        );
      }
      return c;
    }).toList();
    _emitFiltered();
  }
}
