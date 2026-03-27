import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchlistgo/app.dart';
import 'package:watchlistgo/services/connectivity_service.dart';
import 'package:watchlistgo/services/firestore_database_service.dart';
import 'package:watchlistgo/services/watchlist_repository.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    final repository = WatchlistRepository(
      db: FirestoreDatabaseService(),
      connectivity: ConnectivityService(),
    );
    await tester.pumpWidget(WatchlistGo(repository: repository));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
