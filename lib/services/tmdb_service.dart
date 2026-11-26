import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TMDBService {
  static final Map<String, Map<String, dynamic>> _memory = {};

  final FirebaseFunctions _functions;

  TMDBService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'me-west1');

  Future<String> _call(Map<String, Object> request) async {
    final result = await _functions.httpsCallable('tmdb').call(request);
    return json.encode(result.data);
  }

  Future<Map<String, dynamic>?> _cachedGet(
    Map<String, Object> request,
    String cacheKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final body = await _call(request);
      await prefs.setString(cacheKey, body);
      return _memory[cacheKey] = json.decode(body);
    } catch (e) {
      debugPrint('TMDB fetch failed for $cacheKey, falling back to cache: $e');
    }

    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      return _memory[cacheKey] = json.decode(cached);
    }
    return null;
  }

  Map<String, dynamic>? peekDetails(String type, int id) =>
      _memory['tmdb_${type}_$id'];

  Future<List<Map<String, dynamic>>> searchMulti(String query) async {
    try {
      final data = json.decode(await _call({'op': 'search', 'query': query}));
      final results = data['results'] as List;
      return results
          .cast<Map<String, dynamic>>()
          .where((item) => item['media_type'] != 'person')
          .toList();
    } catch (e) {
      debugPrint('TMDB search failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDetails(String type, int id) =>
      _cachedGet({'op': 'details', 'type': type, 'id': id}, 'tmdb_${type}_$id');

  Future<Map<String, dynamic>?> getImages(String type, int id) => _cachedGet({
    'op': 'images',
    'type': type,
    'id': id,
  }, 'tmdb_${type}_images_$id');
}
