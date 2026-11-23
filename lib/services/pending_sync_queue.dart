import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncOpType { addSeries, removeSeries, addMovie, removeMovie }

class SyncOperation {
  final SyncOpType type;
  final int id;

  SyncOperation({required this.type, required this.id});

  Map<String, dynamic> toJson() => {'type': type.name, 'id': id};

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    type: SyncOpType.values.byName(json['type'] as String),
    id: json['id'] as int,
  );
}

class PendingSyncQueue {
  static const _queueKey = 'pending_sync_queue';

  Future<void> enqueue(SyncOperation op) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_queueKey) ?? [];
    existing.add(jsonEncode(op.toJson()));
    await prefs.setStringList(_queueKey, existing);
  }

  Future<List<SyncOperation>> dequeueAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_queueKey) ?? [];
    await prefs.setStringList(_queueKey, []);
    return raw
        .map(
          (e) => SyncOperation.fromJson(jsonDecode(e) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<bool> get hasPending async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_queueKey) ?? [];
    return raw.isNotEmpty;
  }
}
