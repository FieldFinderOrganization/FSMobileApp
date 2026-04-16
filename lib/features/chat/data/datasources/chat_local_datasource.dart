import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session_model.dart';

class ChatLocalDatasource {
  static const _key = 'ai_chat_sessions';

  Future<List<ChatSessionModel>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ChatSessionModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveSession(ChatSessionModel session) async {
    final sessions = await getSessions();
    sessions.insert(0, session);
    await _persist(sessions);
  }

  Future<void> updateSession(ChatSessionModel session) async {
    final sessions = await getSessions();
    final idx = sessions.indexWhere((s) => s.sessionId == session.sessionId);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.insert(0, session);
    }
    await _persist(sessions);
  }

  Future<void> deleteSession(String sessionId) async {
    final sessions = await getSessions();
    sessions.removeWhere((s) => s.sessionId == sessionId);
    await _persist(sessions);
  }

  Future<void> _persist(List<ChatSessionModel> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
