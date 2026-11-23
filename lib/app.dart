import 'package:material_ui/material_ui.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'screens/home_page.dart';
import 'services/watchlist_repository.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class WatchlistGo extends StatelessWidget {
  final WatchlistRepository repository;
  final ThemeController themeController;

  const WatchlistGo({
    super.key,
    required this.repository,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'WatchlistGo',
          themeMode: themeController.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: HomePage(
            repository: repository,
            themeController: themeController,
          ),
        );
      },
    );
  }
}
