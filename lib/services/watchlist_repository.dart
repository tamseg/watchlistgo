import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracked_title.dart';
import 'connectivity_service.dart';
import 'database_service.dart';
import 'library_store.dart';
import 'library_sync.dart';
import 'pending_sync_queue.dart';

enum LinkResult { synced, merged, conflictNeedsConfirmation }

class WatchlistRepository {
  static const _lastLinkedUidKey = 'lastLinkedUid';

  final DatabaseService _db;
  final ConnectivityService _connectivity;
  final String? Function() _currentUid;
  final Future<String?> Function() _restoredUid;
  final DateTime Function() _now;
  final Future<void> Function(List<int> ids) _requestSeries;
  final Future<void> Function(List<int> ids) _requestSeriesDaily;
  final PendingSyncQueue _queue = PendingSyncQueue();
  final LibraryStore _store = LibraryStore();

  final _seriesController = StreamController<List<int>>.broadcast();
  final _moviesController = StreamController<List<MovieRecord>>.broadcast();
  StreamSubscription<bool>? _connectivitySub;

  Map<int, MovieRecord> _movies = {};
  Map<int, SeriesRecord> _series = {};

  @visibleForTesting
  Future<void> startupSync = Future.value();

  WatchlistRepository({
    required DatabaseService db,
    required ConnectivityService connectivity,
    String? Function()? currentUid,
    Future<String?> Function()? restoredUid,
    DateTime Function()? now,
    Future<void> Function(List<int> ids)? requestSeries,
    Future<void> Function(List<int> ids)? requestSeriesDaily,
  }) : _db = db,
       _requestSeries = requestSeries ?? _ignoreRequest,
       _requestSeriesDaily = requestSeriesDaily ?? _ignoreRequest,
       _connectivity = connectivity,
       _currentUid =
           currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _restoredUid =
           restoredUid ??
           (() async =>
               (await FirebaseAuth.instance.authStateChanges().first)?.uid),
       _now = now ?? (() => DateTime.now().toUtc());

  static Future<void> _ignoreRequest(List<int> ids) async {}

  Stream<List<int>> get seriesStream => _seriesController.stream;
  Stream<List<MovieRecord>> get moviesStream => _moviesController.stream;

  List<int> get currentSeriesIds => _activeIds([
    for (final s in _series.values)
      if (!s.removed) (s.tmdbId, s.addedAt),
  ]);

  List<MovieRecord> get currentMovies => List.unmodifiable(
    _activeIds([
      for (final m in _movies.values)
        if (!m.removed) (m.tmdbId, m.addedAt),
    ]).map((id) => _movies[id]!),
  );

  List<int> get currentMoviesIds =>
      List.unmodifiable(currentMovies.map((m) => m.tmdbId));

  static List<int> _activeIds(List<(int, DateTime)> items) {
    items.sort((a, b) {
      final byTime = a.$2.compareTo(b.$2);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
    return List.unmodifiable(items.map((e) => e.$1));
  }

  Future<void> init() async {
    _movies = await _store.loadMovies();
    _series = await _store.loadSeries();
    _emit();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((connected) {
      final uid = _uid;
      if (connected && uid != null) _flushQueue(uid);
    });
    startupSync = _syncWithCloudOnStartup();
    unawaited(startupSync);
  }

  Future<void> _syncWithCloudOnStartup() async {
    final uid = await _restoredUid();
    if (uid == null) {
      unawaited(_requestSeriesDaily(currentSeriesIds));
      return;
    }
    if (!await _connectivity.isConnected) return;

    try {
      await _syncWithCloud(
        uid,
        await _db.getMovieRecords(uid),
        await _db.getSeriesRecords(uid),
      );
    } catch (e) {
      debugPrint('Startup cloud sync failed: $e');
    }
  }

  Future<void> _syncWithCloud(
    String uid,
    Map<int, MovieRecord> cloudMovies,
    Map<int, SeriesRecord> cloudSeries,
  ) async {
    final pending = await _queue.peekAll();
    Set<int> pendingOf(TitleKind kind) => {
      for (final op in pending)
        if (op.kind == kind) op.id,
    };

    final moviePlan = planSync(
      local: _movies,
      cloud: cloudMovies,
      pending: pendingOf(TitleKind.movie),
    );
    final seriesPlan = planSync(
      local: _series,
      cloud: cloudSeries,
      pending: pendingOf(TitleKind.series),
    );

    _movies = moviePlan.merged;
    _series = seriesPlan.merged;
    await _save();
    _emit();

    for (final movie in moviePlan.toUpload) {
      await _sendOrQueue(uid, TitleKind.movie, movie.tmdbId);
    }
    for (final series in seriesPlan.toUpload) {
      await _sendOrQueue(uid, TitleKind.series, series.tmdbId);
    }
    await _flushQueue(uid);
  }

  Future<void> _save() async {
    await _store.saveMovies(_movies);
    await _store.saveSeries(_series);
  }

  void _emit() {
    _moviesController.add(currentMovies);
    _seriesController.add(currentSeriesIds);
  }

  String? get _uid => _currentUid();

  Future<void> addSeries(int id, {String? title}) async {
    final existing = _series[id];
    if (existing != null && !existing.removed) return;
    _series.remove(id);
    _series[id] = SeriesRecord(
      tmdbId: id,
      title: title ?? existing?.title,
      addedAt: _now(),
    );
    await _changed(TitleKind.series, id);
    if (_uid == null) unawaited(_requestSeries([id]));
  }

  Future<void> removeSeries(int id) async {
    final existing = _series[id];
    if (existing == null || existing.removed) return;
    _series[id] = existing.copyWith(removed: true);
    await _changed(TitleKind.series, id);
  }

  Future<void> addMovie(int id, {String? title}) async {
    final existing = _movies[id];
    if (existing != null && !existing.removed) return;
    _movies.remove(id);
    _movies[id] = MovieRecord(
      tmdbId: id,
      title: title ?? existing?.title,
      addedAt: _now(),
    );
    await _changed(TitleKind.movie, id);
  }

  Future<void> removeMovie(int id) async {
    final existing = _movies[id];
    if (existing == null || existing.removed) return;
    _movies[id] = existing.copyWith(removed: true);
    await _changed(TitleKind.movie, id);
  }

  Future<void> setMovieStatus(int id, MovieStatus status) async {
    final existing = _movies[id];
    if (existing == null || existing.removed || existing.status == status) {
      return;
    }
    _movies[id] = existing.copyWith(
      status: status,
      watchedAt: () => status == MovieStatus.watched ? _now() : null,
    );
    await _changed(TitleKind.movie, id);
  }

  Future<void> _changed(TitleKind kind, int id) async {
    await _save();
    _emit();

    final uid = _uid;
    if (uid == null || !await _connectivity.isConnected) {
      await _queue.enqueue(SyncOperation(kind: kind, id: id));
      return;
    }
    await _sendOrQueue(uid, kind, id);
  }

  Future<void> _sendOrQueue(String uid, TitleKind kind, int id) async {
    try {
      await _send(uid, kind, id);
    } catch (e) {
      debugPrint('Sync failed, queuing: $e');
      await _queue.enqueue(SyncOperation(kind: kind, id: id));
    }
  }

  Future<void> _send(String uid, TitleKind kind, int id) async {
    switch (kind) {
      case TitleKind.movie:
        final movie = _movies[id];
        if (movie == null) return;
        await _db.putMovieRecord(uid, movie);
      case TitleKind.series:
        final series = _series[id];
        if (series == null) return;
        await _db.putSeriesRecord(uid, series);
    }
  }

  Future<void> _flushQueue(String uid) async {
    if (!(await _queue.hasPending)) return;
    for (final op in await _queue.dequeueAll()) {
      await _sendOrQueue(uid, op.kind, op.id);
    }
  }

  Future<LinkResult> onAccountLinked(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final lastUid = prefs.getString(_lastLinkedUidKey);
    final wasLinkedToOther = lastUid != null && lastUid != uid;

    final cloudMovies = await _db.getMovieRecords(uid);
    final cloudSeries = await _db.getSeriesRecords(uid);
    final cloudHasData =
        cloudMovies.values.any((m) => !m.removed) ||
        cloudSeries.values.any((s) => !s.removed);
    final localHasData =
        currentMoviesIds.isNotEmpty || currentSeriesIds.isNotEmpty;

    if (wasLinkedToOther && cloudHasData && localHasData) {
      return LinkResult.conflictNeedsConfirmation;
    }

    await _syncWithCloud(uid, cloudMovies, cloudSeries);
    await prefs.setString(_lastLinkedUidKey, uid);
    return localHasData && cloudHasData ? LinkResult.merged : LinkResult.synced;
  }

  Future<void> confirmReplace(String uid) async {
    final prefs = await SharedPreferences.getInstance();

    _movies = await _db.getMovieRecords(uid);
    _series = await _db.getSeriesRecords(uid);
    await _queue.clear();
    await _save();
    _emit();

    await prefs.setString(_lastLinkedUidKey, uid);
  }

  Future<void> clearAll() async {
    for (final id in currentMoviesIds) {
      _movies[id] = _movies[id]!.copyWith(removed: true);
      await _queue.enqueue(SyncOperation(kind: TitleKind.movie, id: id));
    }
    for (final id in currentSeriesIds) {
      _series[id] = _series[id]!.copyWith(removed: true);
      await _queue.enqueue(SyncOperation(kind: TitleKind.series, id: id));
    }
    await _save();
    _emit();

    final uid = _uid;
    if (uid != null) {
      await _db.clearWatchlists(uid);
      await _flushQueue(uid);
    }
  }

  Future<void> forgetLocalLink() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLinkedUidKey);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _seriesController.close();
    _moviesController.close();
  }
}
