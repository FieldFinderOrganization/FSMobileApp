part of 'conversation_list_cubit.dart';

/// Bộ lọc hội thoại theo vai trò đối phương.
enum ConversationFilter { all, provider, shipper }

abstract class ConversationListState extends Equatable {
  const ConversationListState();
  @override
  List<Object?> get props => [];
}

class ConversationListInitial extends ConversationListState {
  const ConversationListInitial();
}

class ConversationListLoading extends ConversationListState {
  const ConversationListLoading();
}

class ConversationListLoaded extends ConversationListState {
  final List<ConversationModel> conversations;
  final ConversationFilter activeFilter;
  const ConversationListLoaded(this.conversations,
      {this.activeFilter = ConversationFilter.all});
  @override
  List<Object?> get props => [conversations, activeFilter];
}

class ConversationListError extends ConversationListState {
  final String message;
  const ConversationListError(this.message);
  @override
  List<Object?> get props => [message];
}
