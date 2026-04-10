import 'package:equatable/equatable.dart';
import 'package:fsmobileapp/features/auth/domain/entities/auth_token_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

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
