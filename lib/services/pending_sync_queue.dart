import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

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

  /// Must match the path excluded in res/xml backup rules.
  static const androidFileName = 'watchlistgo_sync_queue';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync(
    options: defaultTargetPlatform == TargetPlatform.android
        ? const SharedPreferencesAsyncAndroidOptions(
            backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
            originalSharedPreferencesOptions:
                AndroidSharedPreferencesStoreOptions(fileName: androidFileName),
          )
        : const SharedPreferencesOptions(),
  );

  bool _migrated = false;

  Future<void> _migrateLegacyQueue() async {
    if (_migrated) return;
    _migrated = true;
    final legacy = await SharedPreferences.getInstance();
    final old = legacy.getStringList(_queueKey);
    if (old == null) return;
    if (old.isNotEmpty) {
      final current = await _prefs.getStringList(_queueKey) ?? [];
      await _prefs.setStringList(_queueKey, [...old, ...current]);
    }
    await legacy.remove(_queueKey);
  }

  Future<void> enqueue(SyncOperation op) async {
    await _migrateLegacyQueue();
    final existing = await _prefs.getStringList(_queueKey) ?? [];
    existing.add(jsonEncode(op.toJson()));
    await _prefs.setStringList(_queueKey, existing);
  }

  Future<List<SyncOperation>> dequeueAll() async {
    await _migrateLegacyQueue();
    final raw = await _prefs.getStringList(_queueKey) ?? [];
    await _prefs.remove(_queueKey);
    return raw
        .map(
          (e) => SyncOperation.fromJson(jsonDecode(e) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<bool> get hasPending async {
    await _migrateLegacyQueue();
    final raw = await _prefs.getStringList(_queueKey) ?? [];
    return raw.isNotEmpty;
  }
}
