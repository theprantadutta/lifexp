import 'package:flutter/material.dart';

import '../../data/models/user.dart';

/// Provider for current user context throughout the app
class UserContext extends InheritedWidget {
  const UserContext({required this.user, required super.child, super.key});

  final User user;

  static UserContext? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<UserContext>();

  static UserContext of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No UserContext found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(UserContext oldWidget) => user != oldWidget.user;
}

/// Extension to easily get current user from context
extension UserContextExtension on BuildContext {
  User get currentUser => UserContext.of(this).user;
  User? get currentUserOrNull => UserContext.maybeOf(this)?.user;
}
