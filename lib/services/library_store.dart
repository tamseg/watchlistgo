import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracked_title.dart';

class LibraryStore {
  static const _moviesKey = 'movies_v1';
  static const _seriesKey = 'series_v1';

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
