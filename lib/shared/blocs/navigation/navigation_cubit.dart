import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Navigation state
class NavigationState extends Equatable {

  const NavigationState({
    required this.currentIndex,
    required this.currentRoute,
  });
  final int currentIndex;
  final String currentRoute;

  NavigationState copyWith({int? currentIndex, String? currentRoute}) => NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      currentRoute: currentRoute ?? this.currentRoute,
    );

  @override
  List<Object> get props => [currentIndex, currentRoute];
}

/// Navigation cubit for managing bottom navigation state
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit()
    : super(const NavigationState(currentIndex: 0, currentRoute: '/home'));

  /// Change the current tab
  void changeTab(int index) {
    final route = _getRouteForIndex(index);
    emit(state.copyWith(currentIndex: index, currentRoute: route));
  }

  /// Navigate to specific route
  void navigateToRoute(String route) {
    final index = _getIndexForRoute(route);
    emit(state.copyWith(currentIndex: index, currentRoute: route));
  }

  /// Reset to home tab
  void resetToHome() {
    emit(const NavigationState(currentIndex: 0, currentRoute: '/home'));
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/tasks';
      case 2:
        return '/progress';
      case 3:
        return '/world';
      case 4:
        return '/profile';
      default:
        return '/home';
    }
  }

  int _getIndexForRoute(String route) {
    switch (route) {
      case '/home':
        return 0;
      case '/tasks':
        return 1;
      case '/progress':
        return 2;
      case '/world':
        return 3;
      case '/profile':
        return 4;
      default:
        return 0;
    }
  }

  /// Get tab name for current index
  String get currentTabName {
    switch (state.currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Tasks';
      case 2:
        return 'Progress';
      case 3:
        return 'World';
      case 4:
        return 'Profile';
      default:
        return 'Home';
    }
  }

  /// Check if current tab is home
  bool get isHome => state.currentIndex == 0;

  /// Check if current tab is tasks
  bool get isTasks => state.currentIndex == 1;

  /// Check if current tab is progress
  bool get isProgress => state.currentIndex == 2;

  /// Check if current tab is world
  bool get isWorld => state.currentIndex == 3;

  /// Check if current tab is profile
  bool get isProfile => state.currentIndex == 4;

  /// Navigation helper methods
  void navigateToHome() => changeTab(0);
  void navigateToTasks() => changeTab(1);
  void navigateToProgress() => changeTab(2);
  void navigateToWorld() => changeTab(3);
  void navigateToProfile() => changeTab(4);
}
