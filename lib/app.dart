import 'package:material_ui/material_ui.dart';
import 'theme/app_theme.dart';
import 'screens/home_page.dart';
import 'services/watchlist_repository.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class WatchlistGo extends StatelessWidget {
  final WatchlistRepository repository;

  const WatchlistGo({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'WatchlistGo',
      theme: AppTheme.lightTheme,
      home: HomePage(repository: repository),
    );
  }
}
