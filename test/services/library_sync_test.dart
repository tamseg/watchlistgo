import 'package:flutter_test/flutter_test.dart';
import 'package:watchlistgo/models/tracked_title.dart';
import 'package:watchlistgo/services/library_sync.dart';

final _added = DateTime.utc(2026, 1, 1);

MovieRecord movie(
  int id, {
  MovieStatus status = MovieStatus.watchlist,
  bool removed = false,
  DateTime? updatedAt,
}) => MovieRecord(
  tmdbId: id,
  title: 'Movie $id',
  status: status,
  removed: removed,
  addedAt: _added,
  updatedAt: updatedAt,
);

SyncPlan<MovieRecord> plan({
  Map<int, MovieRecord> local = const {},
  Map<int, MovieRecord> cloud = const {},
  Set<int> pending = const {},
}) => planSync(local: local, cloud: cloud, pending: pending);

void main() {
  test('nothing to do when both sides are empty', () {
    final result = plan();

    expect(result.merged, isEmpty);
    expect(result.toUpload, isEmpty);
  });

  test('the cloud copy wins over a local copy that is not pending', () {
    final result = plan(
      local: {1: movie(1)},
      cloud: {1: movie(1, status: MovieStatus.watched)},
    );

    expect(result.merged[1]!.status, MovieStatus.watched);
    expect(result.toUpload, isEmpty);
  });

  test('a pending local edit wins over the cloud copy', () {
    final result = plan(
      local: {1: movie(1, status: MovieStatus.watched)},
      cloud: {1: movie(1)},
      pending: {1},
    );

    expect(result.merged[1]!.status, MovieStatus.watched);
    expect(result.toUpload, isEmpty);
  });

  test('titles only on the phone are kept and uploaded', () {
    final result = plan(local: {1: movie(1)});

    expect(result.merged.keys, [1]);
    expect(result.toUpload.map((m) => m.tmdbId), [1]);
  });

  test('titles only in the cloud are added to the phone', () {
    final result = plan(cloud: {2: movie(2)});

    expect(result.merged.keys, [2]);
    expect(result.toUpload, isEmpty);
  });

  test('a cloud removal beats a stale restored local copy', () {
    final result = plan(
      local: {1: movie(1)},
      cloud: {1: movie(1, removed: true)},
    );

    expect(result.merged[1]!.removed, isTrue);
    expect(result.toUpload, isEmpty);
  });

  test('a pending local removal beats an active cloud copy', () {
    final result = plan(
      local: {1: movie(1, removed: true)},
      cloud: {1: movie(1)},
      pending: {1},
    );

    expect(result.merged[1]!.removed, isTrue);
  });

  test('a pending id without a local record takes the cloud copy', () {
    final result = plan(cloud: {1: movie(1)}, pending: {1});

    expect(result.merged[1], isNotNull);
    expect(result.toUpload, isEmpty);
  });

  test('mixes all cases per title independently', () {
    final result = plan(
      local: {
        1: movie(1),
        2: movie(2, status: MovieStatus.watched),
        3: movie(3),
      },
      cloud: {1: movie(1, removed: true), 2: movie(2), 4: movie(4)},
      pending: {2},
    );

    expect(result.merged.keys, unorderedEquals([1, 2, 3, 4]));
    expect(result.merged[1]!.removed, isTrue);
    expect(result.merged[2]!.status, MovieStatus.watched);
    expect(result.toUpload.map((m) => m.tmdbId), [3]);
  });

  test('works the same for series', () {
    final result = planSync(
      local: {7: SeriesRecord(tmdbId: 7, addedAt: _added)},
      cloud: {8: SeriesRecord(tmdbId: 8, addedAt: _added)},
      pending: const {},
    );

    expect(result.merged.keys, unorderedEquals([7, 8]));
    expect(result.toUpload.map((s) => s.tmdbId), [7]);
  });
}
