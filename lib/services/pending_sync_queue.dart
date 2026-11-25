import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

enum TitleKind { movie, series }

class SyncOperation {
  final TitleKind kind;
  final int id;

  const SyncOperation({required this.kind, required this.id});

  Map<String, dynamic> toJson() => {'kind': kind.name, 'id': id};

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    final legacyType = json['type'] as String?;
    final kind = legacyType != null
        ? (legacyType.endsWith('Series') ? TitleKind.series : TitleKind.movie)
        : TitleKind.values.byName(json['kind'] as String);
    return SyncOperation(kind: kind, id: json['id'] as int);
  }

  @override
  bool operator ==(Object other) =>
      other is SyncOperation && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
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

  Future<List<SyncOperation>> _read() async {
    await _migrateLegacyQueue();
    final raw = await _prefs.getStringList(_queueKey) ?? [];
    return {
      for (final e in raw)
        SyncOperation.fromJson(jsonDecode(e) as Map<String, dynamic>),
    }.toList();
  }

  Future<void> enqueue(SyncOperation op) async {
    final ops = await _read();
    if (ops.contains(op)) return;
    await _prefs.setStringList(_queueKey, [
      for (final o in [...ops, op]) jsonEncode(o.toJson()),
    ]);
  }

  Future<List<SyncOperation>> peekAll() => _read();

  Future<List<SyncOperation>> dequeueAll() async {
    final ops = await _read();
    await _prefs.remove(_queueKey);
    return ops;
  }

  Future<void> clear() async {
    await _migrateLegacyQueue();
    await _prefs.remove(_queueKey);
  }

  Future<bool> get hasPending async => (await _read()).isNotEmpty;
}
