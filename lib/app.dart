import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_page.dart';

class WatchlistGo extends StatelessWidget {
  const WatchlistGo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watchlist Go',
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
