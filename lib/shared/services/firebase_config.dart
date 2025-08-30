import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration and initialization
class FirebaseConfig {
  static bool _initialized = false;
  
  /// Initialize Firebase
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp();
      
      // Configure Firestore settings
      _configureFirestore();
      
      // Configure Auth settings
      _configureAuth();
      
      _initialized = true;
      developer.log('Firebase initialized successfully', name: 'FirebaseConfig');
    } catch (e) {
      developer.log('Failed to initialize Firebase: $e', name: 'FirebaseConfig');
      rethrow;
    }
  }

  /// Configure Firestore settings
  static void _configureFirestore() {
    final firestore = FirebaseFirestore.instance;
    
    // Enable offline persistence
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    // Enable network for real-time updates
    firestore.enableNetwork();
  }

  /// Configure Auth settings
  static void _configureAuth() {
    final auth = FirebaseAuth.instance;
    
    // Configure auth settings if needed
    // For example, set language code
    auth.setLanguageCode('en');
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;
  
  /// Get current user
  static User? get currentUser => FirebaseAuth.instance.currentUser;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
}

/// Firebase authentication helper
class FirebaseAuthHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Sign in anonymously
  static Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      developer.log('Signed in anonymously: ${credential.user?.uid}', name: 'FirebaseAuthHelper');
      return credential.user;
    } catch (e) {
      developer.log('Anonymous sign in failed: $e', name: 'FirebaseAuthHelper');
      rethrow;
    }
  }
  
  /// Sign in with email and password
  static Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      developer.log('Signed in with email: ${credential.user?.email}', name: 'FirebaseAuthHelper');
      return credential.user;
    } catch (e) {
      developer.log('Email sign in failed: $e', name: 'FirebaseAuthHelper');
      rethrow;
    }
  }
  
  /// Create account with email and password
  static Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      developer.log('Created account: ${credential.user?.email}', name: 'FirebaseAuthHelper');
      return credential.user;
    } catch (e) {
      developer.log('Account creation failed: $e', name: 'FirebaseAuthHelper');
      rethrow;
    }
  }
  
  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      developer.log('Signed out successfully', name: 'FirebaseAuthHelper');
    } catch (e) {
      developer.log('Sign out failed: $e', name: 'FirebaseAuthHelper');
      rethrow;
    }
  }
  
  /// Delete current user account
  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }
    
    try {
      await user.delete();
      developer.log('Account deleted successfully', name: 'FirebaseAuthHelper');
    } catch (e) {
      developer.log('Account deletion failed: $e', name: 'FirebaseAuthHelper');
      rethrow;
    }
  }
  
  /// Get auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Get current user
  static User? get currentUser => _auth.currentUser;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
}