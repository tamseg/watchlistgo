import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:watchlistgo/services/connectivity_service.dart';
import 'package:watchlistgo/services/database_service.dart';

void resetPreferences([Map<String, Object> legacy = const {}]) {
  SharedPreferences.setMockInitialValues(legacy);
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
}

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class FakeDatabase implements DatabaseService {
  List<int> series;
  List<int> movies;
  List<int>? staleSeries;
  List<int>? staleMovies;
  bool failReads = false;
  bool failWrites = false;

  FakeDatabase({List<int>? series, List<int>? movies})
    : series = [...?series],
      movies = [...?movies];

  void _checkWrite() {
    if (failWrites) throw Exception('write failed');
  }

  @override
  Future<List<int>> getFollowedSeriesIds(String uid) async {
    if (failReads) throw Exception('read failed');
    return List.of(staleSeries ?? series);
  }

  @override
  Future<List<int>> getFollowedMoviesIds(String uid) async {
    if (failReads) throw Exception('read failed');
    return List.of(staleMovies ?? movies);
  }

  @override
  Future<void> addSeries({required String uid, required int seriesId}) async {
    _checkWrite();
    if (!series.contains(seriesId)) series.add(seriesId);
  }

  @override
  Future<void> removeSeries({
    required String uid,
    required int seriesId,
  }) async {
    _checkWrite();
    series.remove(seriesId);
  }

  @override
  Future<void> addMovie({required String uid, required int movieId}) async {
    _checkWrite();
    if (!movies.contains(movieId)) movies.add(movieId);
  }

  @override
  Future<void> removeMovie({required String uid, required int movieId}) async {
    _checkWrite();
    movies.remove(movieId);
  }

  @override
  Future<void> addFollowedIds({
    required String uid,
    required List<int> seriesIds,
    required List<int> movieIds,
  }) async {
    _checkWrite();
    series = {...series, ...seriesIds}.toList();
    movies = {...movies, ...movieIds}.toList();
  }

  @override
  Future<void> clearWatchlists(String uid) async {
    _checkWrite();
    series = [];
    movies = [];
  }

  @override
  Future<void> createUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {}

  @override
  Future<Map<String, dynamic>?> getUser(String uid) async => null;

  @override
  Future<void> updateUser({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {}

  @override
  Future<void> deleteUser(String uid) async {}

  @override
  Future<void> updateMessagingFid({
    required String uid,
    required String? fid,
  }) async {}
}

class FakeConnectivity implements ConnectivityService {
  bool connected;
  final _changes = StreamController<bool>.broadcast();

  FakeConnectivity({this.connected = true});

  void setConnected(bool value) {
    connected = value;
    _changes.add(value);
  }

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => _changes.stream;

  @override
  void dispose() => _changes.close();
}
