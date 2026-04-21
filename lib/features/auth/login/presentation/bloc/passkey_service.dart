import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/entities/auth_token_entity.dart';

class PasskeyService {
  final AuthRepository _authRepository;
  final PasskeyAuthenticator _authenticator = PasskeyAuthenticator();

  PasskeyService(this._authRepository);

  Future<void> registerPasskey(String userEmail) async {
    // 1. Lấy challenge từ backend
    final startResponse = await _authRepository.passkeyRegisterStart();
    final challengeId = startResponse['challengeId'];

    // 2. Gọi màn hình xác thực vân tay/khuôn mặt của OS
    final nativeResponse = await _authenticator.register(
      RegisterRequestType(
        challenge: startResponse['challenge'],
        relyingParty: RelyingPartyType(
          id: startResponse['rpId'],
          name: startResponse['rpName'],
        ),
        user: UserType(
          id: startResponse['userId'],
          name: startResponse['userName'],
          displayName: startResponse['userDisplayName'] ?? startResponse['userName'],
        ),
        pubKeyCredParams: [
          PubKeyCredParamType(type: 'public-key', alg: -7),   // ES256
          PubKeyCredParamType(type: 'public-key', alg: -257), // RS256
        ],
        excludeCredentials: [],
        timeout: 60000,
        attestation: 'none',
        authSelectionType: AuthenticatorSelectionType(
          authenticatorAttachment: 'platform',
          requireResidentKey: true,
          residentKey: 'required',
          userVerification: 'required',
        ),
      ),
    );

    print('Passkey Registration Debug:');
    print('clientDataJSON: ${nativeResponse.clientDataJSON}');
    print('attestationObject: ${nativeResponse.attestationObject}');
    print('credentialId: ${nativeResponse.id}');

    // 3. Gửi attestation lên backend để lưu
    await _authRepository.passkeyRegisterFinish({
      'challengeId': challengeId,
      'credentialId': nativeResponse.id,
      'displayName': 'Thiết bị của tôi', // Có thể dùng package device_info_plus để lấy tên thật
      'clientDataJSON': nativeResponse.clientDataJSON,
      'attestationObject': nativeResponse.attestationObject,
    });
  }

  Future<AuthTokenEntity> loginWithPasskey(String email) async {
    // 1. Lấy challenge từ backend
    final startResponse = await _authRepository.passkeyLoginStart(email);
    final challengeId = startResponse['challengeId'];

    List<dynamic> allowRaw = startResponse['allowCredentials'] ?? [];
    List<CredentialType> allowCredentials = allowRaw.map((v) => CredentialType(
      id: v.toString(),
      type: 'public-key',
      transports: [],
    )).toList();

    // 2. Gọi màn hình xác thực để lấy chữ ký
    final nativeResponse = await _authenticator.authenticate(
      AuthenticateRequestType(
        challenge: startResponse['challenge'],
        relyingPartyId: startResponse['rpId'],
        allowCredentials: allowCredentials,
        timeout: 60000,
        userVerification: 'required',
        mediation: MediationType.Optional,
        preferImmediatelyAvailableCredentials: true,
      ),
    );

    print('Passkey Login Debug:');
    print('challenge: ${startResponse['challenge']}');
    print('clientDataJSON: ${nativeResponse.clientDataJSON}');
    print('authenticatorData: ${nativeResponse.authenticatorData}');
    print('signature: ${nativeResponse.signature}');
    print('credentialId: ${nativeResponse.id}');

    // 3. Gửi assertion lên backend để verify
    final authToken = await _authRepository.passkeyLoginFinish({
      'challengeId': challengeId,
      'credentialId': nativeResponse.id,
      'clientDataJSON': nativeResponse.clientDataJSON,
      'authenticatorData': nativeResponse.authenticatorData,
      'signature': nativeResponse.signature,
      'userHandle': nativeResponse.userHandle,
    });

    return authToken;
  }
}
