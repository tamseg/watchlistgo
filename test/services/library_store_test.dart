import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watchlistgo/models/tracked_title.dart';
import 'package:watchlistgo/services/library_store.dart';
import 'fakes.dart';

final migrationTime = DateTime.utc(2026, 11, 25, 10);

LibraryStore makeStore() => LibraryStore(now: () => migrationTime);

Future<String?> titleOf(TitleKind kind, int id) async => '${kind.name} $id';

void main() {
  setUp(resetPreferences);

  group('records', () {
    test('movie survives a JSON round trip', () {
      final movie = MovieRecord(
        tmdbId: 948713,
        title: 'The Last Kingdom: Seven Kings Must Die',
        status: MovieStatus.watched,
        removed: true,
        addedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
        updatedAt: DateTime.utc(2026, 2, 3),
        watchedAt: DateTime.utc(2026, 2, 1),
      );

      final copy = MovieRecord.fromJson(movie.toJson());

      expect(copy.tmdbId, movie.tmdbId);
      expect(copy.title, movie.title);
      expect(copy.status, movie.status);
      expect(copy.removed, isTrue);
      expect(copy.addedAt, movie.addedAt);
      expect(copy.updatedAt, movie.updatedAt);
      expect(copy.watchedAt, movie.watchedAt);
      expect(copy.addedAt.isUtc, isTrue);
    });

    test('series survives a JSON round trip without optional fields', () {
      final series = SeriesRecord(tmdbId: 1396, addedAt: DateTime.utc(2026));

      final copy = SeriesRecord.fromJson(series.toJson());

      expect(copy.tmdbId, 1396);
      expect(copy.title, isNull);
      expect(copy.status, SeriesStatus.following);
      expect(copy.removed, isFalse);
      expect(copy.updatedAt, isNull);
    });

    test('times are stored in UTC even if given in local time', () {
      final local = DateTime(2026, 11, 25, 12);
      final movie = MovieRecord(tmdbId: 1, addedAt: local);

      final copy = MovieRecord.fromJson(movie.toJson());

      expect(copy.addedAt, local.toUtc());
      expect(copy.addedAt.isUtc, isTrue);
    });

    test('copyWith can clear watchedAt', () {
      final movie = MovieRecord(
        tmdbId: 1,
        addedAt: migrationTime,
        status: MovieStatus.watched,
        watchedAt: migrationTime,
      );

      final unwatched = movie.copyWith(
        status: MovieStatus.watchlist,
        watchedAt: () => null,
      );

      expect(unwatched.status, MovieStatus.watchlist);
      expect(unwatched.watchedAt, isNull);
    });
  });

  group('store', () {
    test('is empty before anything is saved', () async {
      final store = makeStore();

      expect(await store.loadMovies(), isEmpty);
      expect(await store.loadSeries(), isEmpty);
    });

    test('saves and loads records by TMDB id', () async {
      final store = makeStore();
      await store.saveMovies({
        10: MovieRecord(tmdbId: 10, title: 'A', addedAt: migrationTime),
      });
      await store.saveSeries({
        20: SeriesRecord(tmdbId: 20, title: 'B', addedAt: migrationTime),
      });

      expect((await store.loadMovies())[10]?.title, 'A');
      expect((await store.loadSeries())[20]?.title, 'B');
    });
  });

  group('migration from the old ID lists', () {
    test('creates a record per id with the right defaults', () async {
      resetPreferences({
        'followedMoviesIds': ['10', '11'],
        'followedSeriesIds': ['20'],
      });
      final store = makeStore();

      await store.migrateFromLegacy(titleOf);

      final movies = await store.loadMovies();
      final series = await store.loadSeries();
      expect(movies.keys, [10, 11]);
      expect(movies[10]!.status, MovieStatus.watchlist);
      expect(movies[10]!.title, 'movie 10');
      expect(movies[10]!.addedAt, migrationTime);
      expect(movies[10]!.updatedAt, isNull);
      expect(movies[10]!.removed, isFalse);
      expect(series.keys, [20]);
      expect(series[20]!.status, SeriesStatus.following);
      expect(series[20]!.title, 'series 20');
    });

    test('leaves the title empty when it cannot be looked up', () async {
      resetPreferences({
        'followedMoviesIds': ['10'],
      });
      final store = makeStore();

      await store.migrateFromLegacy((kind, id) async => throw Exception());

      expect((await store.loadMovies())[10]!.title, isNull);
    });

    test('keeps the old ID lists', () async {
      resetPreferences({
        'followedMoviesIds': ['10'],
      });

      await makeStore().migrateFromLegacy(titleOf);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('followedMoviesIds'), ['10']);
    });

    test('does nothing when it already ran', () async {
      resetPreferences({
        'followedMoviesIds': ['10'],
      });
      final store = makeStore();
      await store.migrateFromLegacy(titleOf);
      final movies = await store.loadMovies();
      await store.saveMovies({
        ...movies,
        10: movies[10]!.copyWith(status: MovieStatus.watched),
      });

      await store.migrateFromLegacy(titleOf);

      expect((await store.loadMovies())[10]!.status, MovieStatus.watched);
    });

    test('marks a user with no titles as migrated', () async {
      final store = makeStore();
      var lookups = 0;

      await store.migrateFromLegacy((kind, id) async {
        lookups++;
        return null;
      });

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('movies_v1'), isTrue);
      expect(prefs.containsKey('series_v1'), isTrue);
      expect(lookups, 0);
    });
  });
}
