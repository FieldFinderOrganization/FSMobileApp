import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/user_chat_message_model.dart';

class UserChatWebSocketService {
  final TokenStorage tokenStorage;

  StompClient? _client;
  StompUnsubscribe? _subscription;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  void Function(UserChatMessageModel)? _onMessage;
  void Function()? _onConnected;
  void Function(String)? _onError;
  String? _subscribedReceiverId;

  UserChatWebSocketService({required this.tokenStorage});

  bool get isConnected => _client?.connected ?? false;

  Future<void> connect({
    required String receiverId,
    required void Function(UserChatMessageModel msg) onMessage,
    void Function()? onConnected,
    void Function(String error)? onError,
  }) async {
    _onMessage = onMessage;
    _onConnected = onConnected;
    _onError = onError;
    _subscribedReceiverId = receiverId;

    final token = await tokenStorage.getAccessToken();
    final headers = token != null
        ? {'Authorization': 'Bearer $token'}
        : <String, String>{};

    _client = StompClient(
      config: StompConfig.sockJS(
        url: ApiConstants.wsBaseUrl,
        stompConnectHeaders: headers,
        onConnect: _onConnect,
        onDisconnect: (_) => _onDisconnectHandler(),
        onWebSocketError: (error) => _onError?.call(error.toString()),
        onStompError: (frame) => _onError?.call(frame.body ?? 'STOMP error'),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _retryCount = 0;
    _onConnected?.call();
    if (_subscribedReceiverId != null) {
      _subscription = _client!.subscribe(
        destination: '/topic/messages.$_subscribedReceiverId',
        callback: (frame) {
          if (frame.body != null) {
            try {
              final json = jsonDecode(frame.body!) as Map<String, dynamic>;
              _onMessage?.call(UserChatMessageModel.fromJson(json));
            } catch (_) {}
          }
        },
      );
    }
  }

  void _onDisconnectHandler() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      Future.delayed(const Duration(seconds: 3), () {
        if (_client != null && !(_client!.connected)) {
          _client!.activate();
        }
      });
    }
  }

  void sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String type = 'TEXT',
    String? imageUrl,
  }) {
    if (!isConnected) return;
    _client!.send(
      destination: '/app/chat',
      body: jsonEncode({
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'type': type,
        'imageUrl': ?imageUrl,
      }),
    );
  }

  void disconnect() {
    _retryCount = _maxRetries;
    _subscription?.call();
    _subscription = null;
    _client?.deactivate();
    _client = null;
  }
}
