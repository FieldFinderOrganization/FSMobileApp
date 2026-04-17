part of 'conversation_list_cubit.dart';

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
  const ConversationListLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class ConversationListError extends ConversationListState {
  final String message;
  const ConversationListError(this.message);
  @override
  List<Object?> get props => [message];
}
