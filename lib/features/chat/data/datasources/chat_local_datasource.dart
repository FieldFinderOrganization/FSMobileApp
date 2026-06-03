import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/chat_session_model.dart';

class ChatLocalDatasource {
  ChatLocalDatasource(this.tokenStorage);

  final TokenStorage tokenStorage;

  // Legacy single global bucket from the pre-per-user version. It is NOT owned by any
  // account, so it must be purged — never inherited (inheriting leaked one user's chat
  // to the next account on the same device).
  static const _legacyKey = 'ai_chat_sessions';
  static const _prefix = 'ai_chat_sessions_';

  /// Storage key scoped to the current user → logout no longer wipes history and a second
  /// account on the same device can't read the previous user's chat.
  Future<String> _key() async {
    final uid = await tokenStorage.getUserId();
    return (uid == null || uid.isEmpty) ? '${_prefix}guest' : '$_prefix$uid';
  }

  Future<void> _purgeLegacy(SharedPreferences prefs) async {
    if (prefs.containsKey(_legacyKey)) {
      await prefs.remove(_legacyKey);
    }
  }

  Future<List<ChatSessionModel>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    // Drop the pre-per-user global bucket on first access by anyone — do NOT migrate it
    // into the current user's bucket (that was the cross-account chat leak).
    await _purgeLegacy(prefs);
    final key = await _key();
    final raw = prefs.getString(key);
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
    final key = await _key();
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(key, encoded);
  }
}
