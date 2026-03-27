import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_page.dart';
import 'services/watchlist_repository.dart';

class WatchlistGo extends StatelessWidget {
  final WatchlistRepository repository;

  const WatchlistGo({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watchlist Go',
      theme: AppTheme.lightTheme,
      home: HomePage(repository: repository),
    );
  }
}
