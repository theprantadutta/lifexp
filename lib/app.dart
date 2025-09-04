import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/database/database.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/avatar_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/achievement_repository.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'shared/blocs/analytics/analytics_bloc.dart';
import 'shared/blocs/auth/auth_bloc.dart';
import 'shared/blocs/auth/auth_event.dart';
import 'shared/blocs/avatar/avatar_bloc_exports.dart';
import 'shared/blocs/navigation/navigation_cubit.dart';
import 'shared/blocs/progress/progress_bloc_exports.dart';
import 'shared/blocs/task/task_bloc_exports.dart';
import 'shared/blocs/achievement/achievement_bloc_exports.dart';
import 'shared/blocs/theme/theme_barrel.dart';
import 'shared/themes/lifexp_theme.dart';

/// The main application widget that sets up the app structure,
/// theme, and global providers.
class LifeExpApp extends StatelessWidget {
  const LifeExpApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize database and repositories
    final database = LifeXPDatabase();
    final taskRepository = TaskRepository(database: database);
    final authRepository = AuthRepository();
    final progressRepository = ProgressRepository(database: database);
    final avatarRepository = AvatarRepository(database: database);
    final achievementRepository = AchievementRepository(database: database);

    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationCubit>(create: (_) => NavigationCubit()),
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
        BlocProvider<AuthBloc>(
          create: (_) =>
              AuthBloc(authRepository: authRepository)
                ..add(const AuthCheckRequested()),
        ),
        BlocProvider<TaskBloc>(
          create: (_) => TaskBloc(taskRepository: taskRepository),
        ),
        BlocProvider<ProgressBloc>(
          create: (_) => ProgressBloc(progressRepository: progressRepository),
        ),
        BlocProvider<AvatarBloc>(
          create: (_) => AvatarBloc(avatarRepository: avatarRepository),
        ),
        BlocProvider<AchievementBloc>(
          create: (_) => AchievementBloc(achievementRepository: achievementRepository),
        ),
        BlocProvider<AnalyticsBloc>(
          create: (_) => AnalyticsBloc(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          // Set system UI overlay style for status bar
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeState.isDarkMode
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: themeState.isDarkMode
                  ? Brightness.dark
                  : Brightness.light,
              systemNavigationBarColor: themeState.isDarkMode
                  ? const Color(0xFF1F2937)
                  : Colors.white,
              systemNavigationBarIconBrightness: themeState.isDarkMode
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LifeXP',
            theme: themeState.isDarkMode
                ? LifeXPTheme.darkTheme
                : LifeXPTheme.lightTheme,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}