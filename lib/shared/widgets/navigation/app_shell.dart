import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/analytics/screens/analytics_dashboard_screen.dart';
import '../../../features/home/screens/home_screen.dart';
import '../../../features/profile/screens/profile_screen.dart';
import '../../../features/progress/screens/progress_screen.dart';
import '../../../features/tasks/screens/tasks_screen.dart';
import '../../blocs/navigation/navigation_cubit.dart';
import 'main_navigation.dart';

/// Main app shell that wraps all screens with navigation
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NavigationCubit, NavigationState>(
        builder: (context, state) {
          final scaffoldKey = GlobalKey<ScaffoldState>();

          return MainNavigation(
            currentIndex: state.currentIndex,
            onTabChanged: (index) =>
                context.read<NavigationCubit>().changeTab(index),
            scaffoldKey: scaffoldKey,
            screens: const [
              HomeScreen(),
              TasksScreen(),
              ProgressScreen(),
              AnalyticsDashboardScreen(),
              ProfileScreen(),
            ],
          );
        },
      );
}