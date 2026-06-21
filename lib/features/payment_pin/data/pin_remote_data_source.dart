import '../../../core/network/dio_client.dart';

class PinRemoteDataSource {
  final DioClient dioClient;
  const PinRemoteDataSource({required this.dioClient});

  /// {hasPin, locked, lockedUntil}
  Future<Map<String, dynamic>> status() async {
    final res = await dioClient.dio.get('/wallet/pin/status');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> setPin(String pin) async {
    await dioClient.dio.post('/wallet/pin/set', data: {'pin': pin});
  }

  Future<void> changePin(String currentPin, String newPin) async {
    await dioClient.dio
        .post('/wallet/pin/change', data: {'currentPin': currentPin, 'newPin': newPin});
  }

  Future<void> verify(String pin) async {
    await dioClient.dio.post('/wallet/pin/verify', data: {'pin': pin});
  }

  Future<void> forgot() async {
    await dioClient.dio.post('/wallet/pin/forgot');
  }

  Future<void> reset(String otp, String newPin) async {
    await dioClient.dio.post('/wallet/pin/reset', data: {'otp': otp, 'newPin': newPin});
  }
}
