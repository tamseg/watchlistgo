import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/connectivity_service.dart';
import 'services/firestore_database_service.dart';
import 'services/watchlist_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize();

  final connectivity = ConnectivityService();
  final db = FirestoreDatabaseService();
  final repository = WatchlistRepository(db: db, connectivity: connectivity);
  await repository.init();

  try {
    debugPrint("Firebase initialized successfully.");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  runApp(WatchlistGo(repository: repository));
}
