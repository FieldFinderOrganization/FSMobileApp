import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

/// Một điểm toạ độ shipper nhận từ topic tracking.
class TrackingPoint {
  final double lat;
  final double lng;
  final int ts;
  const TrackingPoint({required this.lat, required this.lng, required this.ts});

  factory TrackingPoint.fromJson(Map<String, dynamic> json) => TrackingPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        ts: (json['ts'] as num?)?.toInt() ?? 0,
      );
}

/// Client STOMP cho real-time tracking vị trí shipper.
/// - Shipper: [connect] rồi gọi [sendLocation] mỗi ~10s.
/// - User/Admin: [connect] với [onPoint] để nhận vị trí live của 1 đơn.
class TrackingWebSocketService {
  final TokenStorage tokenStorage;

  StompClient? _client;
  StompUnsubscribe? _subscription;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  String? _orderId;
  void Function(TrackingPoint)? _onPoint;
  void Function()? _onConnected;
  void Function(String)? _onError;

  TrackingWebSocketService({required this.tokenStorage});

  bool get isConnected => _client?.connected ?? false;

  Future<void> connect({
    required String orderId,
    void Function(TrackingPoint point)? onPoint,
    void Function()? onConnected,
    void Function(String error)? onError,
  }) async {
    _orderId = orderId;
    _onPoint = onPoint;
    _onConnected = onConnected;
    _onError = onError;

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
    // Chỉ subscribe khi cần nhận (user/admin). Shipper truyền onPoint = null.
    if (_orderId != null && _onPoint != null) {
      _subscription = _client!.subscribe(
        destination: '/topic/tracking.$_orderId',
        callback: (frame) {
          if (frame.body != null) {
            try {
              final json = jsonDecode(frame.body!) as Map<String, dynamic>;
              _onPoint?.call(TrackingPoint.fromJson(json));
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

  /// Shipper gửi toạ độ hiện tại tới /app/tracking.
  void sendLocation({
    required String orderId,
    required double lat,
    required double lng,
  }) {
    if (!isConnected) return;
    _client!.send(
      destination: '/app/tracking',
      body: jsonEncode({'orderId': orderId, 'lat': lat, 'lng': lng}),
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
