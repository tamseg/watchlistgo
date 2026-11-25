import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TMDBService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static String get _accessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';

  static Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json;charset=utf-8',
  };

  static final Map<String, Map<String, dynamic>> _memory = {};

  Future<Map<String, dynamic>?> _cachedGet(String url, String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        await prefs.setString(cacheKey, response.body);
        return _memory[cacheKey] = json.decode(response.body);
      }
      debugPrint(
        'TMDB API returned status ${response.statusCode} for $cacheKey',
      );
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
    final response = await http.get(
      Uri.parse('$_baseUrl/search/multi?query=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results
          .cast<Map<String, dynamic>>()
          .where((item) => item['media_type'] != 'person')
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> searchSeries(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search/tv?query=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      if (results.isNotEmpty) {
        return results[0];
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getDetails(String type, int id) async {
    return _cachedGet('$_baseUrl/$type/$id', 'tmdb_${type}_$id');
  }

  Future<Map<String, dynamic>?> getImages(String type, int id) async {
    return _cachedGet(
      '$_baseUrl/$type/$id/images?include_image_language=en,null',
      'tmdb_${type}_images_$id',
    );
  }
}
