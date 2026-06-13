import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/token_storage.dart';

/// Socket thông báo toàn cục — subscribe /topic/notifications.{userId}
/// suốt vòng đời đăng nhập (khác socket chat: chỉ sống trong màn chat).
class NotificationWebSocketService {
  final TokenStorage tokenStorage;

  StompClient? _client;
  StompUnsubscribe? _subscription;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  void Function(Map<String, dynamic>)? _onEvent;
  String? _userId;

  NotificationWebSocketService({required this.tokenStorage});

  bool get isConnected => _client?.connected ?? false;

  Future<void> connect({
    required String userId,
    required void Function(Map<String, dynamic> event) onEvent,
  }) async {
    _onEvent = onEvent;
    _userId = userId;

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
        onWebSocketError: (_) {},
        onStompError: (_) {},
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _retryCount = 0;
    if (_userId != null) {
      _subscription = _client!.subscribe(
        destination: '/topic/notifications.$_userId',
        callback: (frame) {
          if (frame.body != null) {
            try {
              final json = jsonDecode(frame.body!) as Map<String, dynamic>;
              _onEvent?.call(json);
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

  void disconnect() {
    _retryCount = _maxRetries;
    _subscription?.call();
    _subscription = null;
    _client?.deactivate();
    _client = null;
  }
}
