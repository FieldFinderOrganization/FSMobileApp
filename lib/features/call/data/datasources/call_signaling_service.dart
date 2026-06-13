import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/token_storage.dart';

/// Socket signaling cuộc gọi — always-on suốt phiên đăng nhập, sub
/// `/topic/call.{userId}` để nhận INVITE/ANSWER/ICE/... ở bất kỳ màn hình nào.
/// Cùng pattern với [NotificationWebSocketService]; gửi tín hiệu tới `/app/call.signal`.
class CallSignalingService {
  final TokenStorage tokenStorage;

  StompClient? _client;
  StompUnsubscribe? _subscription;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  void Function(Map<String, dynamic>)? _onSignal;
  String? _userId;

  CallSignalingService({required this.tokenStorage});

  bool get isConnected => _client?.connected ?? false;

  Future<void> connect({
    required String userId,
    required void Function(Map<String, dynamic> signal) onSignal,
  }) async {
    _onSignal = onSignal;
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
        destination: '/topic/call.$_userId',
        callback: (frame) {
          if (frame.body != null) {
            try {
              final json = jsonDecode(frame.body!) as Map<String, dynamic>;
              _onSignal?.call(json);
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

  /// Gửi 1 tín hiệu cuộc gọi. `signal` phải chứa key `toId` để BE relay.
  void send(Map<String, dynamic> signal) {
    if (!isConnected) return;
    _client!.send(destination: '/app/call.signal', body: jsonEncode(signal));
  }

  void disconnect() {
    _retryCount = _maxRetries;
    _subscription?.call();
    _subscription = null;
    _client?.deactivate();
    _client = null;
  }
}
