import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watchlistgo/services/watchlist_repository.dart';
import 'fakes.dart';

const uid = 'user-1';

Future<WatchlistRepository> startRepository({
  required FakeDatabase db,
  FakeConnectivity? connectivity,
  String? signedInUid = uid,
  List<int> localSeries = const [],
  List<int> localMovies = const [],
  String? lastLinkedUid,
}) async {
  resetPreferences({
    if (localSeries.isNotEmpty)
      'followedSeriesIds': localSeries.map((e) => '$e').toList(),
    if (localMovies.isNotEmpty)
      'followedMoviesIds': localMovies.map((e) => '$e').toList(),
    'lastLinkedUid': ?lastLinkedUid,
  });
  final repository = WatchlistRepository(
    db: db,
    connectivity: connectivity ?? FakeConnectivity(),
    currentUid: () => signedInUid,
    restoredUid: () async => signedInUid,
  );
  await repository.init();
  await repository.startupSync;
  return repository;
}

Future<List<int>> savedSeries() async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getStringList('followedSeriesIds') ?? [])
      .map(int.parse)
      .toList();
}

void main() {
  group('local changes', () {
    test('are written to the cloud when online', () async {
      final db = FakeDatabase();
      final repository = await startRepository(db: db);

      await repository.addSeries(1);
      await repository.addMovie(2);
      await repository.removeSeries(1);

      expect(db.series, isEmpty);
      expect(db.movies, [2]);
      expect(repository.currentMoviesIds, [2]);
    });

    test('are queued while offline and flushed on reconnect', () async {
      final db = FakeDatabase();
      final connectivity = FakeConnectivity(connected: false);
      final repository = await startRepository(
        db: db,
        connectivity: connectivity,
      );

      await repository.addSeries(1);
      expect(db.series, isEmpty);
      expect(await savedSeries(), [1]);

      connectivity.setConnected(true);
      await settle();
      expect(db.series, [1]);
    });

    test('are queued when a cloud write fails', () async {
      final db = FakeDatabase()..failWrites = true;
      final connectivity = FakeConnectivity();
      final repository = await startRepository(
        db: db,
        connectivity: connectivity,
      );

      await repository.addMovie(3);
      expect(db.movies, isEmpty);

      db.failWrites = false;
      connectivity.setConnected(true);
      await settle();
      expect(db.movies, [3]);
    });

    test('stay local when signed out', () async {
      final db = FakeDatabase();
      final repository = await startRepository(db: db, signedInUid: null);

      await repository.addSeries(1);

      expect(db.series, isEmpty);
      expect(repository.currentSeriesIds, [1]);
    });
  });

  group('startup refresh', () {
    test('replaces stale local lists with the cloud lists', () async {
      final db = FakeDatabase(series: [1, 2, 3], movies: [10, 11]);
      final repository = await startRepository(
        db: db,
        localSeries: [1],
        localMovies: [10],
      );

      expect(repository.currentSeriesIds, [1, 2, 3]);
      expect(repository.currentMoviesIds, [10, 11]);
      expect(await savedSeries(), [1, 2, 3]);
    });

    test('never writes to the cloud', () async {
      final db = FakeDatabase(series: [1, 2, 3]);
      await startRepository(db: db, localSeries: [9]);

      expect(db.series, [1, 2, 3]);
    });

    test('is skipped when signed out', () async {
      final db = FakeDatabase(series: [1, 2, 3]);
      final repository = await startRepository(
        db: db,
        signedInUid: null,
        localSeries: [1],
      );

      expect(repository.currentSeriesIds, [1]);
    });

    test('keeps local lists when the cloud is empty', () async {
      final db = FakeDatabase();
      final repository = await startRepository(db: db, localSeries: [1]);

      expect(repository.currentSeriesIds, [1]);
    });

    test('keeps local lists when the cloud read fails', () async {
      final db = FakeDatabase(series: [1, 2])..failReads = true;
      final repository = await startRepository(db: db, localSeries: [5]);

      expect(repository.currentSeriesIds, [5]);
    });
  });

  group('account linking', () {
    test('never removes cloud items when local lists are stale', () async {
      final db = FakeDatabase(series: [1, 2, 3, 4], movies: [10, 11]);
      final repository = await startRepository(
        db: db,
        signedInUid: null,
        localSeries: [1, 2],
        localMovies: [10],
        lastLinkedUid: uid,
      );

      final result = await repository.onAccountLinked(uid);

      expect(result, LinkResult.merged);
      expect(db.series, unorderedEquals([1, 2, 3, 4]));
      expect(db.movies, unorderedEquals([10, 11]));
      expect(repository.currentSeriesIds, unorderedEquals([1, 2, 3, 4]));
      expect(repository.currentMoviesIds, unorderedEquals([10, 11]));
    });

    test('never removes cloud items even if the cloud read is stale', () async {
      final db = FakeDatabase(series: [1, 2, 3, 4], movies: [10, 11])
        ..staleSeries = [1, 2]
        ..staleMovies = [10];
      final repository = await startRepository(
        db: db,
        signedInUid: null,
        localSeries: [1, 2],
        localMovies: [10],
        lastLinkedUid: uid,
      );

      await repository.onAccountLinked(uid);

      expect(db.series, unorderedEquals([1, 2, 3, 4]));
      expect(db.movies, unorderedEquals([10, 11]));
    });

    test('adds local-only items to the cloud', () async {
      final db = FakeDatabase(series: [1, 2]);
      final repository = await startRepository(
        db: db,
        signedInUid: null,
        localSeries: [2, 5],
      );

      await repository.onAccountLinked(uid);

      expect(db.series, unorderedEquals([1, 2, 5]));
      expect(repository.currentSeriesIds, unorderedEquals([1, 2, 5]));
    });

    test('uploads local lists to an empty cloud', () async {
      final db = FakeDatabase();
      final repository = await startRepository(
        db: db,
        signedInUid: null,
        localSeries: [1],
        localMovies: [10],
      );

      final result = await repository.onAccountLinked(uid);

      expect(result, LinkResult.synced);
      expect(db.series, [1]);
      expect(db.movies, [10]);
    });

    test('downloads cloud lists when local is empty', () async {
      final db = FakeDatabase(series: [1, 2], movies: [10]);
      final repository = await startRepository(db: db, signedInUid: null);

      final result = await repository.onAccountLinked(uid);

      expect(result, LinkResult.synced);
      expect(repository.currentSeriesIds, [1, 2]);
      expect(repository.currentMoviesIds, [10]);
    });

    test('asks before mixing data from a different account', () async {
      final db = FakeDatabase(series: [1]);
      final repository = await startRepository(
        db: db,
        signedInUid: null,
        localSeries: [9],
        lastLinkedUid: 'someone-else',
      );

      final result = await repository.onAccountLinked(uid);

      expect(result, LinkResult.conflictNeedsConfirmation);
      expect(db.series, [1]);
      expect(repository.currentSeriesIds, [9]);
    });

    test('fails without touching the cloud when it cannot read it', () async {
      final db = FakeDatabase(series: [1, 2])..failReads = true;
      final repository = await startRepository(
        db: db,
        signedInUid: null,
        localSeries: [9],
      );

      await expectLater(repository.onAccountLinked(uid), throwsException);
      expect(db.series, [1, 2]);
    });
  });
}
