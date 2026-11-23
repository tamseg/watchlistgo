import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watchlistgo/app.dart';
import 'package:watchlistgo/services/connectivity_service.dart';
import 'package:watchlistgo/services/firestore_database_service.dart';
import 'package:watchlistgo/services/watchlist_repository.dart';
import 'package:watchlistgo/theme/theme_controller.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final themeController = ThemeController(prefs);
    final repository = WatchlistRepository(
      db: FirestoreDatabaseService(),
      connectivity: ConnectivityService(),
    );
    await tester.pumpWidget(WatchlistGo(
      repository: repository,
      themeController: themeController,
    ));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}