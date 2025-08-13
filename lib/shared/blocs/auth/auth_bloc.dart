import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for managing authentication state and operations
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<AuthStatusRequested>(_onAuthStatusRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthProfileUpdateRequested>(_onAuthProfileUpdateRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthErrorOccurred>(_onAuthErrorOccurred);

    // Listen to auth state changes
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) {
        add(AuthStatusChanged(user: user));
      },
      onError: (error) {
        print('AuthBloc: Auth state stream error: $error');
        add(const AuthErrorOccurred(message: 'Authentication error occurred'));
      },
    );
  }

  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  /// Handles checking authentication status
  Future<void> _onAuthStatusRequested(
    AuthStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // The auth state stream will handle emitting the correct state
      print('AuthBloc: Checking authentication status');
    } on Exception catch (e, stackTrace) {
      print('AuthBloc: Error checking auth status: $e');
      print('Stack trace: $stackTrace');
      emit(const AuthError(message: 'Failed to check authentication status'));
    }
  }

  /// Handles sign up requests
  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSignUpLoading());

    try {
      print('AuthBloc: Processing sign up request for ${event.email}');

      final user = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );

      print('AuthBloc: Sign up successful for user ${user.id}');
      // The auth state stream will emit AuthAuthenticated
    } on Exception catch (e, stackTrace) {
      print('AuthBloc: Sign up error: $e');
      print('Stack trace: $stackTrace');

      emit(
        AuthError(
          message: e.toString().replaceFirst('Exception: ', ''),
          isSignUp: true,
        ),
      );
    }
  }

  /// Handles sign in requests
  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSignInLoading());

    try {
      print('AuthBloc: Processing sign in request for ${event.email}');

      final user = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );

      print('AuthBloc: Sign in successful for user ${user.id}');
      // The auth state stream will emit AuthAuthenticated
    } on Exception catch (e, stackTrace) {
      print('AuthBloc: Sign in error: $e');
      print('Stack trace: $stackTrace');

      emit(
        AuthError(
          message: e.toString().replaceFirst('Exception: ', ''),
          isSignIn: true,
        ),
      );
    }
  }

  /// Handles sign out requests
  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Processing sign out request');
      await _authRepository.signOut();
      // The auth state stream will emit AuthUnauthenticated
    } on Exception catch (e, stackTrace) {
      print('AuthBloc: Sign out error: $e');
      print('Stack trace: $stackTrace');

      emit(AuthError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Handles password reset requests
  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Processing password reset request for ${event.email}');

      await _authRepository.sendPasswordResetEmail(event.email);

      emit(AuthPasswordResetSent(email: event.email));
      print('AuthBloc: Password reset email sent successfully');
    } on Exception catch (e, stackTrace) {
      print('AuthBloc: Password reset error: $e');
      print('Stack trace: $stackTrace');

      emit(
        AuthError(
          message: e.toString().replaceFirst('Exception: ', ''),
          isPasswordReset: true,
        ),
      );
    }
  }

  /// Handles profile update requests
  Future<void> _onAuthProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthProfileUpdateLoading());

    try {
      print('AuthBloc: Processing profile update request');

      final user = await _authRepository.updateProfile(
        fullName: event.fullName,
        photoUrl: event.photoUrl,
      );

      emit(AuthProfileUpdated(user: user));
      print('AuthBloc: Profile updated successfully');
    } on Exception catch (e, stackTrace) {
      print('AuthBloc: Profile update error: $e');
      print('Stack trace: $stackTrace');

      emit(AuthError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Handles auth status changes from stream
  void _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthAuthenticated(user: event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Handles auth errors from stream
  void _onAuthErrorOccurred(
    AuthErrorOccurred event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthError(message: event.message));
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    _authRepository.dispose();
    return super.close();
  }
}
