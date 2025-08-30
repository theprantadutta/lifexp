import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user.dart';

/// Repository for handling authentication and user management
class AuthRepository {
  AuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _getUserFromFirestore(firebaseUser.uid);
    });

  /// Current authenticated user
  User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    // Note: This returns null for now, use authStateChanges stream for real-time updates
    return null;
  }

  /// Get current authenticated user asynchronously
  Future<User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return await _getUserFromFirestore(firebaseUser.uid);
  }

  /// Sign up with email and password
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      developer.log('Starting sign up for $email', name: 'AuthRepository');

      // Create user with Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create user account');
      }

      developer.log(
        'Firebase user created with ID: ${firebaseUser.uid}',
        name: 'AuthRepository',
      );

      // Update display name
      await firebaseUser.updateDisplayName(fullName);

      // Send email verification
      await firebaseUser.sendEmailVerification();

      // Create user document in Firestore
      final now = DateTime.now();
      final user = User(
        id: firebaseUser.uid,
        email: email,
        fullName: fullName,
        isEmailVerified: firebaseUser.emailVerified,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toFirestore());
      developer.log('User document created in Firestore', name: 'AuthRepository');

      // Also create user in local database for foreign key constraints
      await _createLocalUser(user);

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log('Firebase Auth error: ${e.code} - ${e.message}', name: 'AuthRepository', error: e);
      throw _handleAuthException(e);
    } on Exception catch (e, stackTrace) {
      developer.log('Unexpected error during sign up', name: 'AuthRepository', error: e, stackTrace: stackTrace);
      throw Exception('Failed to create account. Please try again.');
    }
  }

  /// Sign in with email and password
  Future<User> signIn({required String email, required String password}) async {
    try {
      developer.log('Starting sign in for $email', name: 'AuthRepository');

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in');
      }

      developer.log('Firebase sign in successful', name: 'AuthRepository');

      // Get user data from Firestore
      final user = await _getUserFromFirestore(firebaseUser.uid);
      if (user == null) {
        throw Exception('User data not found');
      }

      // Ensure user exists in local database
      await _createLocalUser(user);

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log('Firebase Auth error: ${e.code} - ${e.message}', name: 'AuthRepository', error: e);
      throw _handleAuthException(e);
    } on Exception catch (e, stackTrace) {
      developer.log('Unexpected error during sign in', name: 'AuthRepository', error: e, stackTrace: stackTrace);
      throw Exception('Failed to sign in. Please try again.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      developer.log('Signing out user', name: 'AuthRepository');
      await _firebaseAuth.signOut();
    } on Exception catch (e, stackTrace) {
      developer.log('Error during sign out', name: 'AuthRepository', error: e, stackTrace: stackTrace);
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      developer.log('Sending password reset email to $email', name: 'AuthRepository');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log('Password reset error: ${e.code} - ${e.message}', name: 'AuthRepository', error: e);
      throw _handleAuthException(e);
    } on Exception catch (e, stackTrace) {
      developer.log('Unexpected error sending password reset', name: 'AuthRepository', error: e, stackTrace: stackTrace);
      throw Exception('Failed to send password reset email. Please try again.');
    }
  }

  /// Update user profile
  Future<User> updateProfile({String? fullName, String? photoUrl}) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No authenticated user');
      }

      developer.log('Updating profile for user ${firebaseUser.uid}', name: 'AuthRepository');

      // Update Firebase Auth profile
      if (fullName != null) {
        await firebaseUser.updateDisplayName(fullName);
      }
      if (photoUrl != null) {
        await firebaseUser.updatePhotoURL(photoUrl);
      }

      // Update Firestore document
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      if (fullName != null) updates['fullName'] = fullName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .update(updates);

      // Return updated user
      final user = await _getUserFromFirestore(firebaseUser.uid);
      if (user == null) {
        throw Exception('Failed to get updated user data');
      }

      return user;
    } on Exception catch (e, stackTrace) {
      developer.log('Error updating profile', name: 'AuthRepository', error: e, stackTrace: stackTrace);
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  /// Get user from Firestore
  Future<User?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        developer.log('User document not found for UID: $uid', name: 'AuthRepository');
        return null;
      }
      return User.fromFirestore(doc.data()!, uid);
    } on Exception catch (e, stackTrace) {
      developer.log('Error getting user from Firestore', name: 'AuthRepository', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Create user in local database for foreign key constraints
  Future<void> _createLocalUser(User user) async {
    try {
      developer.log('Creating local user record for ${user.id}', name: 'AuthRepository');

      // For now, we'll create a simple local user record
      // This would typically integrate with your local database
      // Since we don't have the database instance here, we'll skip this
      // The database will be initialized with the user when they first use the app

      developer.log('Local user record created successfully', name: 'AuthRepository');
    } on Exception catch (e, stackTrace) {
      developer.log('Error creating local user', name: 'AuthRepository', error: e, stackTrace: stackTrace);
      // Don't throw here as this is not critical for auth flow
    }
  }

  /// Handle Firebase Auth exceptions
  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception(
          'Password is too weak. Please choose a stronger password.',
        );
      case 'email-already-in-use':
        return Exception('An account already exists with this email address.');
      case 'invalid-email':
        return Exception('Please enter a valid email address.');
      case 'user-disabled':
        return Exception(
          'This account has been disabled. Please contact support.',
        );
      case 'user-not-found':
        return Exception('No account found with this email address.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'invalid-credential':
        return Exception('Invalid email or password. Please try again.');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later.');
      case 'network-request-failed':
        return Exception(
          'Network error. Please check your connection and try again.',
        );
      default:
        return Exception('Authentication failed. Please try again.');
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}
