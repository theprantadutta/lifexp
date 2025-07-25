import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The main application widget that sets up the app structure,
/// theme, and global providers.
class LifeExpApp extends StatelessWidget {
  const LifeExpApp({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: const [
      // Global BLoCs will be added here
    ],
    child: MaterialApp(
      title: 'LifeExp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('LifeExp - Gamification App')),
      ),
    ),
  );
}
