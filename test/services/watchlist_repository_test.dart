import 'package:flutter_test/flutter_test.dart';
import 'package:watchlistgo/models/tracked_title.dart';
import 'package:watchlistgo/services/library_store.dart';
import 'package:watchlistgo/services/watchlist_repository.dart';
import 'fakes.dart';

const uid = 'user-1';
final _start = DateTime.utc(2026, 11, 25);

MovieRecord movie(
  int id, {
  bool removed = false,
  MovieStatus status = MovieStatus.watchlist,
  int addedMinute = 0,
}) => MovieRecord(
  tmdbId: id,
  title: 'Movie $id',
  status: status,
  removed: removed,
  addedAt: _start.add(Duration(minutes: addedMinute)),
);

SeriesRecord series(int id, {bool removed = false, int addedMinute = 0}) =>
    SeriesRecord(
      tmdbId: id,
      title: 'Series $id',
      removed: removed,
      addedAt: _start.add(Duration(minutes: addedMinute)),
    );

Map<int, T> byId<T>(List<T> records, int Function(T) id) => {
  for (final r in records) id(r): r,
};

class TestClock {
  var _minutes = 1000;
  DateTime now() => _start.add(Duration(minutes: _minutes++));
}

class Harness {
  final FakeDatabase db;
  final FakeConnectivity connectivity;
  final WatchlistRepository repository;
  String? signedInUid;

  Harness._(this.db, this.connectivity, this.repository, this.signedInUid);
}

Future<Harness> start({
  FakeDatabase? db,
  FakeConnectivity? connectivity,
  String? signedInUid = uid,
  List<MovieRecord> localMovies = const [],
  List<SeriesRecord> localSeries = const [],
  String? lastLinkedUid,
  bool keepStorage = false,
}) async {
  if (!keepStorage) {
    resetPreferences({'lastLinkedUid': ?lastLinkedUid});
    final store = LibraryStore();
    await store.saveMovies(byId(localMovies, (m) => m.tmdbId));
    await store.saveSeries(byId(localSeries, (s) => s.tmdbId));
  }

  final database = db ?? FakeDatabase();
  final network = connectivity ?? FakeConnectivity();
  late final Harness harness;
  final clock = TestClock();
  final repository = WatchlistRepository(
    db: database,
    connectivity: network,
    currentUid: () => harness.signedInUid,
    restoredUid: () async => signedInUid,
    now: clock.now,
  );
  harness = Harness._(database, network, repository, signedInUid);
  await repository.init();
  await repository.startupSync;
  return harness;
}

void main() {
  group('local changes', () {
    test('are written as records and to the old lists', () async {
      final h = await start();

      await h.repository.addMovie(10, title: 'Dune');
      await h.repository.addSeries(20, title: 'Fallout');

      expect(h.db.movieRecords[10]!.title, 'Dune');
      expect(h.db.movieRecords[10]!.removed, isFalse);
      expect(h.db.seriesRecords[20]!.title, 'Fallout');
      expect(h.db.movies, [10]);
      expect(h.db.series, [20]);
    });

    test('removals become markers and leave the old lists', () async {
      final h = await start();
      await h.repository.addMovie(10);

      await h.repository.removeMovie(10);

      expect(h.repository.currentMoviesIds, isEmpty);
      expect(h.db.movieRecords[10]!.removed, isTrue);
      expect(h.db.movies, isEmpty);
    });

    test('keep the order titles were added in', () async {
      final h = await start();

      await h.repository.addSeries(3);
      await h.repository.addSeries(1);
      await h.repository.addSeries(2);

      expect(h.repository.currentSeriesIds, [3, 1, 2]);
    });

    test('re-adding a removed title puts it at the end', () async {
      final h = await start();
      await h.repository.addSeries(1);
      await h.repository.addSeries(2);
      await h.repository.removeSeries(1);

      await h.repository.addSeries(1);

      expect(h.repository.currentSeriesIds, [2, 1]);
      expect(h.db.seriesRecords[1]!.removed, isFalse);
    });

    test('are survived by a restart', () async {
      final h = await start();
      await h.repository.addMovie(10, title: 'Dune');

      final again = await start(
        db: h.db,
        signedInUid: null,
        localMovies: [movie(10)],
      );

      expect(again.repository.currentMoviesIds, [10]);
    });

    test('are queued while offline and sent on reconnect', () async {
      final network = FakeConnectivity(connected: false);
      final h = await start(connectivity: network);

      await h.repository.addSeries(1);
      expect(h.db.seriesRecords, isEmpty);

      network.setConnected(true);
      await settle();
      expect(h.db.seriesRecords.keys, [1]);
      expect(h.db.series, [1]);
    });

    test('are queued when a cloud write fails', () async {
      final network = FakeConnectivity();
      final h = await start(connectivity: network);
      h.db.failWrites = true;

      await h.repository.addMovie(3);
      expect(h.db.movieRecords, isEmpty);

      h.db.failWrites = false;
      network.setConnected(true);
      await settle();
      expect(h.db.movieRecords.keys, [3]);
    });
  });

  group('startup sync', () {
    test('takes cloud records over stale local ones', () async {
      final db = FakeDatabase();
      db.movieRecords.addAll({
        1: movie(1, status: MovieStatus.watched),
        2: movie(2, addedMinute: 1),
      });
      final h = await start(db: db, localMovies: [movie(1)]);

      expect(h.repository.currentMoviesIds, [1, 2]);
    });

    test('a cloud removal beats a restored stale copy', () async {
      final db = FakeDatabase();
      db.seriesRecords[5] = series(5, removed: true);
      final h = await start(db: db, localSeries: [series(5)]);

      expect(h.repository.currentSeriesIds, isEmpty);
    });

    test('uploads titles the cloud does not have', () async {
      final h = await start(localMovies: [movie(1)]);

      expect(h.db.movieRecords.keys, [1]);
      expect(h.db.movies, [1]);
    });

    test('keeps a local edit that is still waiting to be sent', () async {
      final db = FakeDatabase();
      db.movieRecords[1] = movie(1);
      final first = await start(db: db, localMovies: [movie(1)]);
      db.failWrites = true;
      await first.repository.removeMovie(1);

      final again = await start(db: db, keepStorage: true);

      expect(db.movieRecords[1]!.removed, isFalse);
      expect(again.repository.currentMoviesIds, isEmpty);
    });

    test('keeps titles stored on the phone across a restart', () async {
      final first = await start(localMovies: [movie(1)]);
      await first.repository.addMovie(2);

      final again = await start(db: first.db, keepStorage: true);

      expect(again.repository.currentMoviesIds, [1, 2]);
    });

    test('is skipped when signed out', () async {
      final db = FakeDatabase();
      db.movieRecords[1] = movie(1);
      final h = await start(db: db, signedInUid: null);

      expect(h.repository.currentMoviesIds, isEmpty);
    });

    test('keeps local records when the cloud read fails', () async {
      final db = FakeDatabase()..failReads = true;
      final h = await start(db: db, localSeries: [series(5)]);

      expect(h.repository.currentSeriesIds, [5]);
    });

    test('never writes over cloud records', () async {
      final db = FakeDatabase();
      db.movieRecords[1] = movie(1, status: MovieStatus.watched);
      await start(db: db, localMovies: [movie(1)]);

      expect(db.movieRecords[1]!.status, MovieStatus.watched);
    });
  });

  group('account linking', () {
    test('restored stale lists never remove or revive cloud titles', () async {
      final db = FakeDatabase();
      db.seriesRecords.addAll({
        1: series(1),
        2: series(2, removed: true),
        3: series(3, addedMinute: 1),
      });
      final h = await start(
        db: db,
        signedInUid: null,
        localSeries: [series(1), series(2)],
        lastLinkedUid: uid,
      );
      h.signedInUid = uid;

      await h.repository.onAccountLinked(uid);

      expect(h.repository.currentSeriesIds, [1, 3]);
      expect(db.seriesRecords[2]!.removed, isTrue);
      expect(db.seriesRecords[3]!.removed, isFalse);
    });

    test('sends edits made while signed out', () async {
      final db = FakeDatabase();
      db.movieRecords[1] = movie(1);
      final h = await start(db: db, signedInUid: null, localMovies: [movie(1)]);
      await h.repository.removeMovie(1);
      await h.repository.addMovie(2);
      expect(db.movieRecords[1]!.removed, isFalse);
      h.signedInUid = uid;

      await h.repository.onAccountLinked(uid);

      expect(db.movieRecords[1]!.removed, isTrue);
      expect(db.movieRecords[2]!.removed, isFalse);
      expect(h.repository.currentMoviesIds, [2]);
    });

    test('uploads local titles to an empty cloud', () async {
      final db = FakeDatabase();
      final h = await start(db: db, signedInUid: null, localMovies: [movie(1)]);
      h.signedInUid = uid;

      final result = await h.repository.onAccountLinked(uid);

      expect(result, LinkResult.synced);
      expect(db.movieRecords.keys, [1]);
    });

    test('downloads cloud titles to an empty phone', () async {
      final db = FakeDatabase();
      db.seriesRecords[7] = series(7);
      final h = await start(db: db, signedInUid: null);
      h.signedInUid = uid;

      final result = await h.repository.onAccountLinked(uid);

      expect(result, LinkResult.synced);
      expect(h.repository.currentSeriesIds, [7]);
    });

    test('asks before mixing data from a different account', () async {
      final db = FakeDatabase();
      db.movieRecords[1] = movie(1);
      final h = await start(
        db: db,
        signedInUid: null,
        localMovies: [movie(9)],
        lastLinkedUid: 'someone-else',
      );
      h.signedInUid = uid;

      final result = await h.repository.onAccountLinked(uid);

      expect(result, LinkResult.conflictNeedsConfirmation);
      expect(db.movieRecords.keys, [1]);
      expect(h.repository.currentMoviesIds, [9]);
    });

    test('fails without touching the cloud when it cannot be read', () async {
      final db = FakeDatabase()..failReads = true;
      db.movieRecords[1] = movie(1);
      final h = await start(db: db, signedInUid: null, localMovies: [movie(9)]);
      h.signedInUid = uid;

      await expectLater(h.repository.onAccountLinked(uid), throwsException);
      expect(db.movieRecords.keys, [1]);
    });
  });

  test(
    'replacing local data takes the cloud records and drops unsent edits',
    () async {
      final db = FakeDatabase();
      db.movieRecords[1] = movie(1);
      final h = await start(db: db, signedInUid: null, localMovies: [movie(9)]);
      await h.repository.addMovie(8);
      h.signedInUid = uid;

      await h.repository.confirmReplace(uid);
      await h.repository.onAccountLinked(uid);

      expect(h.repository.currentMoviesIds, [1]);
      expect(db.movieRecords.keys, [1]);
    },
  );

  test('clearing marks every title removed locally and in the cloud', () async {
    final h = await start();
    await h.repository.addMovie(1);
    await h.repository.addSeries(2);

    await h.repository.clearAll();

    expect(h.repository.currentMoviesIds, isEmpty);
    expect(h.repository.currentSeriesIds, isEmpty);
    expect(h.db.movieRecords[1]!.removed, isTrue);
    expect(h.db.seriesRecords[2]!.removed, isTrue);
    expect(h.db.movies, isEmpty);
    expect(h.db.series, isEmpty);
  });
}
