import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/ai_chat_remote_datasource.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_session_model.dart';
import 'chat_state.dart';

String _generateId() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class ChatCubit extends Cubit<ChatState> {
  final AIChatRemoteDatasource remoteDatasource;
  final ChatLocalDatasource localDatasource;

  ChatCubit({
    required this.remoteDatasource,
    required this.localDatasource,
  }) : super(const ChatInitial());

  Future<void> loadSessions() async {
    final sessions = await localDatasource.getSessions();
    emit(ChatSessionListLoaded(sessions));
  }

  Future<void> createSession() async {
    final now = DateTime.now();
    final session = ChatSessionModel(
      sessionId: _generateId(),
      title: 'Cuộc trò chuyện mới',
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
    await localDatasource.saveSession(session);
    emit(ChatSessionOpen(session: session));
  }

  Future<void> openSession(String sessionId) async {
    final sessions = await localDatasource.getSessions();
    final session = sessions.firstWhere((s) => s.sessionId == sessionId);
    emit(ChatSessionOpen(session: session));
  }

  Future<void> deleteSession(String sessionId) async {
    await localDatasource.deleteSession(sessionId);
    await loadSessions();
  }

  Future<void> sendMessage(String text) async {
    final current = state;
    if (current is! ChatSessionOpen || current.isLoading) return;

    final userMsg = ChatMessageModel(
      id: _generateId(),
      content: text,
      isUser: true,
      isImage: false,
      createdAt: DateTime.now(),
    );

    final updatedMessages = [...current.session.messages, userMsg];
    final isFirstMessage = current.session.messages.isEmpty;
    final newTitle = isFirstMessage
        ? (text.length > 30 ? text.substring(0, 30) : text)
        : current.session.title;

    var updatedSession = current.session.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
      messages: updatedMessages,
    );

    emit(ChatSessionOpen(session: updatedSession, isLoading: true));

    try {
      final response = await remoteDatasource.sendMessage(
        text,
        current.session.sessionId,
      );

      final aiMessage = response['message'] as String? ?? '';
      final aiData = response['data'] as Map<String, dynamic>?;

      final aiMsg = ChatMessageModel(
        id: _generateId(),
        content: aiMessage,
        isUser: false,
        isImage: false,
        createdAt: DateTime.now(),
        aiData: aiData,
      );

      updatedSession = updatedSession.copyWith(
        updatedAt: DateTime.now(),
        messages: [...updatedSession.messages, aiMsg],
      );

      await localDatasource.updateSession(updatedSession);
      emit(ChatSessionOpen(session: updatedSession));
    } catch (e) {
      // Giữ tin nhắn user, hiện lỗi dưới dạng AI message
      final errMsg = ChatMessageModel(
        id: _generateId(),
        content: 'Đã có lỗi xảy ra. Vui lòng thử lại.',
        isUser: false,
        isImage: false,
        createdAt: DateTime.now(),
      );
      updatedSession = updatedSession.copyWith(
        messages: [...updatedSession.messages, errMsg],
      );
      await localDatasource.updateSession(updatedSession);
      emit(ChatSessionOpen(session: updatedSession));
    }
  }

  Future<void> sendImage(File imageFile) async {
    final current = state;
    if (current is! ChatSessionOpen || current.isLoading) return;

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final userMsg = ChatMessageModel(
      id: _generateId(),
      content: '[Hình ảnh]',
      isUser: true,
      isImage: true,
      imagePath: imageFile.path,
      createdAt: DateTime.now(),
    );

    final isFirstMessage = current.session.messages.isEmpty;
    final newTitle = isFirstMessage ? '🖼 Tìm kiếm bằng hình ảnh' : current.session.title;

    var updatedSession = current.session.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
      messages: [...current.session.messages, userMsg],
    );

    emit(ChatSessionOpen(session: updatedSession, isLoading: true));

    try {
      final response = await remoteDatasource.sendImage(
        base64Image,
        current.session.sessionId,
      );

      final aiMessage = response['message'] as String? ?? '';
      final aiData = response['data'] as Map<String, dynamic>?;

      final aiMsg = ChatMessageModel(
        id: _generateId(),
        content: aiMessage,
        isUser: false,
        isImage: false,
        createdAt: DateTime.now(),
        aiData: aiData,
      );

      updatedSession = updatedSession.copyWith(
        updatedAt: DateTime.now(),
        messages: [...updatedSession.messages, aiMsg],
      );

      await localDatasource.updateSession(updatedSession);
      emit(ChatSessionOpen(session: updatedSession));
    } catch (e) {
      final errMsg = ChatMessageModel(
        id: _generateId(),
        content: 'Đã có lỗi xảy ra khi xử lý hình ảnh. Vui lòng thử lại.',
        isUser: false,
        isImage: false,
        createdAt: DateTime.now(),
      );
      updatedSession = updatedSession.copyWith(
        messages: [...updatedSession.messages, errMsg],
      );
      await localDatasource.updateSession(updatedSession);
      emit(ChatSessionOpen(session: updatedSession));
    }
  }

  void backToList() {
    loadSessions();
  }
}
