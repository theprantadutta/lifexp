import 'package:equatable/equatable.dart';

/// User model for authentication and profile data
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.level = 1,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isEmailVerified = false,
  });

  /// Creates a user from Firebase Auth and Firestore data
  factory User.fromFirestore(Map<String, dynamic> data, String id) => User(
      id: id,
      email: data['email'] as String,
      fullName: data['fullName'] as String,
      photoUrl: data['photoUrl'] as String?,
      level: data['level'] as int? ?? 1,
      totalXP: data['totalXP'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int),
    );

  final String id;
  final String email;
  final String fullName;
  final String? photoUrl;
  final int level;
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Converts user to Firestore document
  Map<String, dynamic> toFirestore() => {
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'level': level,
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };

  /// Creates a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? photoUrl,
    int? level,
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    photoUrl,
    level,
    totalXP,
    currentStreak,
    longestStreak,
    isEmailVerified,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() => 'User(id: $id, email: $email, fullName: $fullName)';
}
