import 'package:equatable/equatable.dart';

import '../../../data/models/user.dart';

/// Base class for all authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check authentication status on app start
class AuthStatusRequested extends AuthEvent {
  const AuthStatusRequested();
}

/// Event to check authentication status on app start (alternative name)
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event to login with email and password (alternative name)
class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Event to sign up with email and password (alternative name)
class SignUpRequested extends AuthEvent {
  const SignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
  });

  final String email;
  final String password;
  final String fullName;

  @override
  List<Object?> get props => [email, password, fullName];
}

/// Event for guest login
class GuestLoginRequested extends AuthEvent {
  const GuestLoginRequested();
}

/// Event to sign up with email and password
class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
  });

  final String email;
  final String password;
  final String fullName;

  @override
  List<Object?> get props => [email, password, fullName];
}

/// Event to sign in with email and password
class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Event to sign out
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event to send password reset email
class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Event to update user profile
class AuthProfileUpdateRequested extends AuthEvent {
  const AuthProfileUpdateRequested({this.fullName, this.photoUrl});

  final String? fullName;
  final String? photoUrl;

  @override
  List<Object?> get props => [fullName, photoUrl];
}

/// Event when auth status changes from stream
class AuthStatusChanged extends AuthEvent {
  const AuthStatusChanged({required this.user});

  final User? user;

  @override
  List<Object?> get props => [user];
}

/// Event when an error occurs in auth stream
class AuthErrorOccurred extends AuthEvent {
  const AuthErrorOccurred({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
