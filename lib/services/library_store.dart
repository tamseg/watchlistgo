import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracked_title.dart';

enum TitleKind { movie, series }

typedef TitleLookup = Future<String?> Function(TitleKind kind, int tmdbId);

class LibraryStore {
  static const _moviesKey = 'movies_v1';
  static const _seriesKey = 'series_v1';
  static const _legacyMoviesKey = 'followedMoviesIds';
  static const _legacySeriesKey = 'followedSeriesIds';

  final DateTime Function() _now;

  LibraryStore({DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  Future<Map<int, MovieRecord>> loadMovies() async {
    final raw = (await SharedPreferences.getInstance()).getString(_moviesKey);
    return _decode(raw, MovieRecord.fromJson);
  }

  Future<Map<int, SeriesRecord>> loadSeries() async {
    final raw = (await SharedPreferences.getInstance()).getString(_seriesKey);
    return _decode(raw, SeriesRecord.fromJson);
  }

  Future<void> saveMovies(Map<int, MovieRecord> movies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _moviesKey,
      jsonEncode({for (final m in movies.values) '${m.tmdbId}': m.toJson()}),
    );
  }

  Future<void> saveSeries(Map<int, SeriesRecord> series) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _seriesKey,
      jsonEncode({for (final s in series.values) '${s.tmdbId}': s.toJson()}),
    );
  }

  Future<void> migrateFromLegacy(TitleLookup lookupTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final now = _now();

    if (!prefs.containsKey(_moviesKey)) {
      final movies = <int, MovieRecord>{
        for (final id in _legacyIds(prefs, _legacyMoviesKey))
          id: MovieRecord(
            tmdbId: id,
            title: await _safeLookup(lookupTitle, TitleKind.movie, id),
            addedAt: now,
          ),
      };
      await saveMovies(movies);
    }

    if (!prefs.containsKey(_seriesKey)) {
      final series = <int, SeriesRecord>{
        for (final id in _legacyIds(prefs, _legacySeriesKey))
          id: SeriesRecord(
            tmdbId: id,
            title: await _safeLookup(lookupTitle, TitleKind.series, id),
            addedAt: now,
          ),
      };
      await saveSeries(series);
    }
  }

  List<int> _legacyIds(SharedPreferences prefs, String key) =>
      (prefs.getStringList(key) ?? []).map(int.parse).toList();

  Future<String?> _safeLookup(
    TitleLookup lookupTitle,
    TitleKind kind,
    int id,
  ) async {
    try {
      return await lookupTitle(kind, id);
    } catch (_) {
      return null;
    }
  }

  Map<int, T> _decode<T>(
    String? raw,
    T Function(Map<String, Object?>) fromJson,
  ) {
    if (raw == null) return {};
    final entries = (jsonDecode(raw) as Map<String, dynamic>).entries;
    return {
      for (final e in entries)
        int.parse(e.key): fromJson(e.value as Map<String, Object?>),
    };
  }
}
