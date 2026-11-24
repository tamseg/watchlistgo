import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'database_service.dart';
import 'pending_sync_queue.dart';

enum LinkResult { synced, merged, conflictNeedsConfirmation }

enum SaveTarget { series, movies, all }

class WatchlistRepository {
  static const _seriesKey = 'followedSeriesIds';
  static const _moviesKey = 'followedMoviesIds';
  static const _lastLinkedUidKey = 'lastLinkedUid';

  final DatabaseService _db;
  final ConnectivityService _connectivity;
  final String? Function() _currentUid;
  final Future<String?> Function() _restoredUid;
  final PendingSyncQueue _queue = PendingSyncQueue();

  final _seriesController = StreamController<List<int>>.broadcast();
  final _moviesController = StreamController<List<int>>.broadcast();
  StreamSubscription<bool>? _connectivitySub;

  List<int> _seriesIds = [];
  List<int> _moviesIds = [];

  @visibleForTesting
  Future<void> startupSync = Future.value();

  WatchlistRepository({
    required DatabaseService db,
    required ConnectivityService connectivity,
    String? Function()? currentUid,
    Future<String?> Function()? restoredUid,
  }) : _db = db,
       _connectivity = connectivity,
       _currentUid =
           currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _restoredUid =
           restoredUid ??
           (() async =>
               (await FirebaseAuth.instance.authStateChanges().first)?.uid);

  Stream<List<int>> get seriesStream => _seriesController.stream;
  Stream<List<int>> get moviesStream => _moviesController.stream;
  List<int> get currentSeriesIds => List.unmodifiable(_seriesIds);
  List<int> get currentMoviesIds => List.unmodifiable(_moviesIds);

  Future<void> init() async {
    await _loadLocal();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((connected) {
      if (connected) _flushQueue();
    });
    startupSync = _syncWithCloudOnStartup();
    unawaited(startupSync);
  }

  Future<void> _syncWithCloudOnStartup() async {
    final uid = await _restoredUid();
    if (uid == null || !await _connectivity.isConnected) return;

    await _flushQueue();
    if (await _queue.hasPending) return;

    try {
      final cloudSeries = await _db.getFollowedSeriesIds(uid);
      final cloudMovies = await _db.getFollowedMoviesIds(uid);

      final cloudEmpty = cloudSeries.isEmpty && cloudMovies.isEmpty;
      final localEmpty = _seriesIds.isEmpty && _moviesIds.isEmpty;
      if (cloudEmpty && !localEmpty) return;

      if (!listEquals(cloudSeries, _seriesIds)) {
        _seriesIds = cloudSeries;
        _seriesController.add(_seriesIds);
      }
      if (!listEquals(cloudMovies, _moviesIds)) {
        _moviesIds = cloudMovies;
        _moviesController.add(_moviesIds);
      }
      await _saveLocal();
    } catch (e) {
      debugPrint('Startup cloud refresh failed: $e');
    }
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _seriesIds = (prefs.getStringList(_seriesKey) ?? [])
        .map((e) => int.parse(e))
        .toList();
    _moviesIds = (prefs.getStringList(_moviesKey) ?? [])
        .map((e) => int.parse(e))
        .toList();
    _seriesController.add(_seriesIds);
    _moviesController.add(_moviesIds);
  }

  Future<void> _saveLocal({SaveTarget target = SaveTarget.all}) async {
    final prefs = await SharedPreferences.getInstance();
    if (target == SaveTarget.series || target == SaveTarget.all) {
      if (_seriesIds.isEmpty) {
        await prefs.remove(_seriesKey);
      } else {
        await prefs.setStringList(
          _seriesKey,
          _seriesIds.map((e) => e.toString()).toList(),
        );
      }
    }
    if (target == SaveTarget.movies || target == SaveTarget.all) {
      if (_moviesIds.isEmpty) {
        await prefs.remove(_moviesKey);
      } else {
        await prefs.setStringList(
          _moviesKey,
          _moviesIds.map((e) => e.toString()).toList(),
        );
      }
    }
  }

  String? get _uid => _currentUid();

  Future<void> addSeries(int id) async {
    if (_seriesIds.contains(id)) return;
    _seriesIds.add(id);
    _seriesController.add(_seriesIds);
    await _saveLocal(target: SaveTarget.series);
    await _syncOp(SyncOperation(type: SyncOpType.addSeries, id: id));
  }

  Future<void> removeSeries(int id) async {
    if (!_seriesIds.contains(id)) return;
    _seriesIds.remove(id);
    _seriesController.add(_seriesIds);
    await _saveLocal(target: SaveTarget.series);
    await _syncOp(SyncOperation(type: SyncOpType.removeSeries, id: id));
  }

  Future<void> addMovie(int id) async {
    if (_moviesIds.contains(id)) return;
    _moviesIds.add(id);
    _moviesController.add(_moviesIds);
    await _saveLocal(target: SaveTarget.movies);
    await _syncOp(SyncOperation(type: SyncOpType.addMovie, id: id));
  }

  Future<void> removeMovie(int id) async {
    if (!_moviesIds.contains(id)) return;
    _moviesIds.remove(id);
    _moviesController.add(_moviesIds);
    await _saveLocal(target: SaveTarget.movies);
    await _syncOp(SyncOperation(type: SyncOpType.removeMovie, id: id));
  }

  Future<void> _syncOp(SyncOperation op) async {
    final uid = _uid;
    if (uid == null) return;

    if (await _connectivity.isConnected) {
      try {
        await _executeOp(uid, op);
      } catch (e) {
        debugPrint('Sync failed, queuing: $e');
        await _queue.enqueue(op);
      }
    } else {
      await _queue.enqueue(op);
    }
  }

  Future<void> _executeOp(String uid, SyncOperation op) async {
    switch (op.type) {
      case SyncOpType.addSeries:
        await _db.addSeries(uid: uid, seriesId: op.id);
      case SyncOpType.removeSeries:
        await _db.removeSeries(uid: uid, seriesId: op.id);
      case SyncOpType.addMovie:
        await _db.addMovie(uid: uid, movieId: op.id);
      case SyncOpType.removeMovie:
        await _db.removeMovie(uid: uid, movieId: op.id);
    }
  }

  Future<void> _flushQueue() async {
    final uid = _uid;
    if (uid == null) return;
    if (!(await _queue.hasPending)) return;

    final ops = await _queue.dequeueAll();
    for (final op in ops) {
      try {
        await _executeOp(uid, op);
      } catch (e) {
        debugPrint('Flush failed for op, re-queuing: $e');
        await _queue.enqueue(op);
      }
    }
  }

  Future<LinkResult> onAccountLinked(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final lastUid = prefs.getString(_lastLinkedUidKey);
    final wasLinkedToOther = lastUid != null && lastUid != uid;

    final cloudSeries = await _db.getFollowedSeriesIds(uid);
    final cloudMovies = await _db.getFollowedMoviesIds(uid);
    final cloudHasData = cloudSeries.isNotEmpty || cloudMovies.isNotEmpty;
    final localHasData = _seriesIds.isNotEmpty || _moviesIds.isNotEmpty;

    if (wasLinkedToOther && cloudHasData && localHasData) {
      return LinkResult.conflictNeedsConfirmation;
    }

    if (localHasData) {
      await _db.addFollowedIds(
        uid: uid,
        seriesIds: _seriesIds,
        movieIds: _moviesIds,
      );
    }

    _seriesIds = {..._seriesIds, ...cloudSeries}.toList();
    _moviesIds = {..._moviesIds, ...cloudMovies}.toList();
    _seriesController.add(_seriesIds);
    _moviesController.add(_moviesIds);
    await _saveLocal();

    await prefs.setString(_lastLinkedUidKey, uid);
    await _flushQueue();
    return localHasData && cloudHasData ? LinkResult.merged : LinkResult.synced;
  }

  Future<void> confirmReplace(String uid) async {
    final prefs = await SharedPreferences.getInstance();

    final cloudSeries = await _db.getFollowedSeriesIds(uid);
    final cloudMovies = await _db.getFollowedMoviesIds(uid);

    _seriesIds = cloudSeries;
    _moviesIds = cloudMovies;
    _seriesController.add(_seriesIds);
    _moviesController.add(_moviesIds);
    await _saveLocal();

    await prefs.setString(_lastLinkedUidKey, uid);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _seriesController.close();
    _moviesController.close();
  }

  Future<void> clearLocalCache() async {
    _seriesIds = [];
    _moviesIds = [];
    _seriesController.add(_seriesIds);
    _moviesController.add(_moviesIds);
    await _saveLocal();
  }

  Future<void> clearAll() async {
    await clearLocalCache();
    final uid = _uid;
    if (uid != null) {
      await _db.clearWatchlists(uid);
    }
  }

  Future<void> forgetLocalLink() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLinkedUidKey);
  }
}
