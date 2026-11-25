import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchlistgo/models/tracked_title.dart';
import 'package:watchlistgo/services/firestore_records.dart';

void main() {
  test('movie converts to a Firestore document and back', () {
    final movie = MovieRecord(
      tmdbId: 948713,
      title: 'The Last Kingdom: Seven Kings Must Die',
      status: MovieStatus.watched,
      addedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
      watchedAt: DateTime.utc(2026, 2, 1),
    );

    final data = movieToFirestore(movie);
    final updatedAt = DateTime.utc(2026, 11, 25, 12);
    final copy = movieFromFirestore({
      ...data,
      'updatedAt': Timestamp.fromDate(updatedAt),
    });

    expect(data['addedAt'], isA<Timestamp>());
    expect(data.containsKey('updatedAt'), isFalse);
    expect(copy.tmdbId, movie.tmdbId);
    expect(copy.title, movie.title);
    expect(copy.status, MovieStatus.watched);
    expect(copy.addedAt, movie.addedAt);
    expect(copy.watchedAt, movie.watchedAt);
    expect(copy.updatedAt, updatedAt);
    expect(copy.addedAt.isUtc, isTrue);
  });

  test('series converts to a Firestore document and back', () {
    final series = SeriesRecord(
      tmdbId: 1396,
      title: 'Breaking Bad',
      removed: true,
      addedAt: DateTime.utc(2026),
    );

    final copy = seriesFromFirestore(seriesToFirestore(series));

    expect(copy.tmdbId, 1396);
    expect(copy.title, 'Breaking Bad');
    expect(copy.status, SeriesStatus.following);
    expect(copy.removed, isTrue);
    expect(copy.updatedAt, isNull);
  });
}
