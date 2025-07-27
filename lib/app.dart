import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'shared/blocs/navigation/navigation_cubit.dart';
import 'shared/blocs/theme/theme_barrel.dart';
import 'shared/themes/lifexp_theme.dart';
import 'shared/widgets/navigation/app_shell.dart';

/// The main application widget that sets up the app structure,
/// theme, and global providers.
class LifeExpApp extends StatelessWidget {
  const LifeExpApp({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<NavigationCubit>(create: (_) => NavigationCubit()),
      BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
    ],
    child: BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LifeXP',
        theme: themeState.isDarkMode
            ? LifeXPTheme.darkTheme
            : LifeXPTheme.lightTheme,
        home: const AppShell(),
      ),
    ),
  );
}
