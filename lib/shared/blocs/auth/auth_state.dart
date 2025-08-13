import 'package:equatable/equatable.dart';

import '../../../data/models/user.dart';

/// Base class for all authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when authentication status is unknown
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when checking authentication status
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when user is authenticated
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  final User user;

  @override
  List<Object?> get props => [user];
}

/// State when user is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// State when authentication operation fails
class AuthError extends AuthState {
  const AuthError({
    required this.message,
    this.isSignUp = false,
    this.isSignIn = false,
    this.isPasswordReset = false,
  });

  final String message;
  final bool isSignUp;
  final bool isSignIn;
  final bool isPasswordReset;

  @override
  List<Object?> get props => [message, isSignUp, isSignIn, isPasswordReset];
}

/// State when sign up is in progress
class AuthSignUpLoading extends AuthState {
  const AuthSignUpLoading();
}

/// State when sign in is in progress
class AuthSignInLoading extends AuthState {
  const AuthSignInLoading();
}

/// State when password reset email is sent successfully
class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// State when profile update is in progress
class AuthProfileUpdateLoading extends AuthState {
  const AuthProfileUpdateLoading();
}

/// State when profile is updated successfully
class AuthProfileUpdated extends AuthState {
  const AuthProfileUpdated({required this.user});

  final User user;

  @override
  List<Object?> get props => [user];
}
