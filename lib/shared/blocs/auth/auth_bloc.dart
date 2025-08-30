import 'dart:async';
import 'dart:developer' as developer;

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
    on<AuthCheckRequested>(_onAuthStatusRequested); // Use same handler as AuthStatusRequested
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
        developer.log('Auth state stream error: $error', name: 'AuthBloc');
        add(const AuthErrorOccurred(message: 'Authentication error occurred'));
      },
    );
  }

  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  /// Handles checking authentication status
  Future<void> _onAuthStatusRequested(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // The auth state stream will handle emitting the correct state
      developer.log('Checking authentication status', name: 'AuthBloc');
    } on Exception catch (e, stackTrace) {
      developer.log('Error checking auth status: $e', name: 'AuthBloc', error: e, stackTrace: stackTrace);
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
      developer.log('Processing sign up request for ${event.email}', name: 'AuthBloc');

      final user = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );

      developer.log('Sign up successful for user ${user.id}', name: 'AuthBloc');
      // The auth state stream will emit AuthAuthenticated
    } on Exception catch (e, stackTrace) {
      developer.log('Sign up error: $e', name: 'AuthBloc', error: e, stackTrace: stackTrace);

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
      developer.log('Processing sign in request for ${event.email}', name: 'AuthBloc');

      final user = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );

      developer.log('Sign in successful for user ${user.id}', name: 'AuthBloc');
      // The auth state stream will emit AuthAuthenticated
    } on Exception catch (e, stackTrace) {
      developer.log('Sign in error: $e', name: 'AuthBloc', error: e, stackTrace: stackTrace);

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
      developer.log('Processing sign out request', name: 'AuthBloc');
      await _authRepository.signOut();
      // The auth state stream will emit AuthUnauthenticated
    } on Exception catch (e, stackTrace) {
      developer.log('Sign out error: $e', name: 'AuthBloc', error: e, stackTrace: stackTrace);

      emit(AuthError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Handles password reset requests
  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      developer.log('Processing password reset request for ${event.email}', name: 'AuthBloc');

      await _authRepository.sendPasswordResetEmail(event.email);

      emit(AuthPasswordResetSent(email: event.email));
      developer.log('Password reset email sent successfully', name: 'AuthBloc');
    } on Exception catch (e, stackTrace) {
      developer.log('Password reset error: $e', name: 'AuthBloc', error: e, stackTrace: stackTrace);

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
      developer.log('Processing profile update request', name: 'AuthBloc');

      final user = await _authRepository.updateProfile(
        fullName: event.fullName,
        photoUrl: event.photoUrl,
      );

      emit(AuthProfileUpdated(user: user));
      developer.log('Profile updated successfully', name: 'AuthBloc');
    } on Exception catch (e, stackTrace) {
      developer.log('Profile update error: $e', name: 'AuthBloc', error: e, stackTrace: stackTrace);

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
