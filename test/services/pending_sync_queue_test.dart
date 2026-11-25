import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watchlistgo/services/pending_sync_queue.dart';
import 'fakes.dart';

const movie1 = SyncOperation(kind: TitleKind.movie, id: 1);
const series2 = SyncOperation(kind: TitleKind.series, id: 2);

void main() {
  setUp(resetPreferences);

  test('starts empty', () async {
    final queue = PendingSyncQueue();
    expect(await queue.hasPending, isFalse);
    expect(await queue.dequeueAll(), isEmpty);
  });

  test('keeps titles in order, once each', () async {
    final queue = PendingSyncQueue();
    await queue.enqueue(movie1);
    await queue.enqueue(series2);
    await queue.enqueue(movie1);

    expect(await queue.peekAll(), [movie1, series2]);
    expect(await queue.dequeueAll(), [movie1, series2]);
    expect(await queue.hasPending, isFalse);
  });

  test('clear empties the queue', () async {
    final queue = PendingSyncQueue();
    await queue.enqueue(movie1);

    await queue.clear();

    expect(await queue.hasPending, isFalse);
  });

  test('reads old add/remove entries from the legacy location', () async {
    resetPreferences({
      'pending_sync_queue': [
        jsonEncode({'type': 'addMovie', 'id': 7}),
        jsonEncode({'type': 'removeSeries', 'id': 8}),
      ],
    });
    final queue = PendingSyncQueue();

    expect(await queue.dequeueAll(), [
      const SyncOperation(kind: TitleKind.movie, id: 7),
      const SyncOperation(kind: TitleKind.series, id: 8),
    ]);

    final legacy = await SharedPreferences.getInstance();
    expect(legacy.getStringList('pending_sync_queue'), isNull);
  });
}
