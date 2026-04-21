import 'package:equatable/equatable.dart';
import '../../../domain/entities/auth_token_entity.dart';
import '../../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  UserEntity? get currentUser {
    final state = this;
    if (state is AuthSuccess) return state.authToken.user;
    if (state is AuthOtpVerified) return state.authToken.user;
    return null;
  }

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final AuthTokenEntity authToken;

  const AuthSuccess(this.authToken);

  @override
  List<Object?> get props => [authToken];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthRegisterSuccess extends AuthState {
  const AuthRegisterSuccess();
}

class AuthOtpSent extends AuthState {
  final AuthTokenEntity pendingToken;
  final String email;

  const AuthOtpSent({required this.pendingToken, required this.email});

  @override
  List<Object?> get props => [pendingToken, email];
}

class AuthOtpVerified extends AuthState {
  final AuthTokenEntity authToken;

  const AuthOtpVerified(this.authToken);

  @override
  List<Object?> get props => [authToken];
}

class AuthChangePasswordVerifySuccess extends AuthState {
  const AuthChangePasswordVerifySuccess();
}

class AuthChangePasswordOtpVerified extends AuthState {
  const AuthChangePasswordOtpVerified();
}

class AuthChangePasswordSuccess extends AuthState {
  const AuthChangePasswordSuccess();
}

class AuthPasskeyRegistered extends AuthState {
  const AuthPasskeyRegistered();
}

class AuthPasskeyRegisterFailure extends AuthState {
  final String message;

  const AuthPasskeyRegisterFailure(this.message);

  @override
  List<Object?> get props => [message];
}
