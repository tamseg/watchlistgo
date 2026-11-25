import 'package:flutter_test/flutter_test.dart';
import 'package:watchlistgo/models/tracked_title.dart';
import 'package:watchlistgo/services/library_store.dart';
import 'fakes.dart';

final someTime = DateTime.utc(2026, 11, 25, 10);

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
        addedAt: someTime,
        status: MovieStatus.watched,
        watchedAt: someTime,
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
      final store = LibraryStore();

      expect(await store.loadMovies(), isEmpty);
      expect(await store.loadSeries(), isEmpty);
    });

    test('saves and loads records by TMDB id', () async {
      final store = LibraryStore();
      await store.saveMovies({
        10: MovieRecord(tmdbId: 10, title: 'A', addedAt: someTime),
      });
      await store.saveSeries({
        20: SeriesRecord(tmdbId: 20, title: 'B', addedAt: someTime),
      });

      expect((await store.loadMovies())[10]?.title, 'A');
      expect((await store.loadSeries())[20]?.title, 'B');
    });
  });
}
