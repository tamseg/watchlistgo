import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/connectivity_service.dart';
import 'services/firestore_database_service.dart';
import 'services/notification_service.dart';
import 'services/series_request_service.dart';
import 'services/watchlist_repository.dart';
import 'theme/theme_controller.dart';
import 'package:mcp_toolkit/mcp_toolkit.dart';
import 'package:flutter/foundation.dart';

late final NotificationService notificationService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    MCPToolkitBinding.instance.initialize();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  const appCheckDebug =
      kDebugMode || bool.fromEnvironment('APP_CHECK_DEBUG');
  await FirebaseAppCheck.instance.activate(
    providerAndroid: appCheckDebug
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: appCheckDebug
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
  await GoogleSignIn.instance.initialize();

  final connectivity = ConnectivityService();
  final db = FirestoreDatabaseService();
  final seriesRequests = SeriesRequestService();
  final repository = WatchlistRepository(
    db: db,
    connectivity: connectivity,
    requestSeries: seriesRequests.request,
    requestSeriesDaily: seriesRequests.requestDaily,
  );
  await repository.init();

  notificationService = NotificationService(db: db);
  await notificationService.init();

  final themeController = ThemeController(prefs);

  runApp(
    // ListenableBuilder(
      // listenable: themeController,
      // builder: (context, child) {
        WatchlistGo(
          repository: repository,
          themeController: themeController,
        ),
      // },
    // ),
  );
}
