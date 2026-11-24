import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watchlistgo/services/pending_sync_queue.dart';
import 'fakes.dart';

void main() {
  setUp(resetPreferences);

  test('starts empty', () async {
    final queue = PendingSyncQueue();
    expect(await queue.hasPending, isFalse);
    expect(await queue.dequeueAll(), isEmpty);
  });

  test('dequeues operations in order and clears the queue', () async {
    final queue = PendingSyncQueue();
    await queue.enqueue(SyncOperation(type: SyncOpType.addSeries, id: 1));
    await queue.enqueue(SyncOperation(type: SyncOpType.removeMovie, id: 2));

    expect(await queue.hasPending, isTrue);
    final ops = await queue.dequeueAll();
    expect(ops.map((op) => (op.type, op.id)), [
      (SyncOpType.addSeries, 1),
      (SyncOpType.removeMovie, 2),
    ]);
    expect(await queue.hasPending, isFalse);
  });

  test('moves a queue left in the legacy location', () async {
    resetPreferences({
      'pending_sync_queue': [
        jsonEncode({'type': 'addMovie', 'id': 7}),
      ],
    });
    final queue = PendingSyncQueue();

    final ops = await queue.dequeueAll();
    expect(ops.map((op) => (op.type, op.id)), [(SyncOpType.addMovie, 7)]);

    final legacy = await SharedPreferences.getInstance();
    expect(legacy.getStringList('pending_sync_queue'), isNull);
  });
}
