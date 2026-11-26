import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:watchlistgo/models/tracked_title.dart';
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
  bool failReads = false;
  bool failWrites = false;

  final movieRecords = <int, MovieRecord>{};
  final seriesRecords = <int, SeriesRecord>{};
  DateTime serverTime = DateTime.utc(2026, 11, 25, 12);

  void _checkWrite() {
    if (failWrites) throw Exception('write failed');
  }

  void _checkRead() {
    if (failReads) throw Exception('read failed');
  }

  @override
  Future<Map<int, MovieRecord>> getMovieRecords(String uid) async {
    _checkRead();
    return Map.of(movieRecords);
  }

  @override
  Future<Map<int, SeriesRecord>> getSeriesRecords(String uid) async {
    _checkRead();
    return Map.of(seriesRecords);
  }

  @override
  Future<void> putMovieRecord(String uid, MovieRecord record) async {
    _checkWrite();
    movieRecords[record.tmdbId] = record.copyWith(updatedAt: serverTime);
  }

  @override
  Future<void> putSeriesRecord(String uid, SeriesRecord record) async {
    _checkWrite();
    seriesRecords[record.tmdbId] = record.copyWith(updatedAt: serverTime);
  }

  @override
  Future<void> clearWatchlists(String uid) async {
    _checkWrite();
    movieRecords.updateAll(
      (_, r) => r.copyWith(removed: true, updatedAt: serverTime),
    );
    seriesRecords.updateAll(
      (_, r) => r.copyWith(removed: true, updatedAt: serverTime),
    );
  }

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
