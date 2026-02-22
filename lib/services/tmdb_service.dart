import 'dart:convert';
import 'package:http/http.dart' as http;

class TMDBService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _accessToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0MjlhMTkzODA0NGJkOGFiYmYwN2YxNWEwNTExNDNhOCIsIm5iZiI6MTc1OTI1MzAzMS41NTksInN1YiI6IjY4ZGMxMjI3YjQ1OWMyMTQyODJkZjUyYyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.gmt_WiwIbszN9M8TcdYL4U7RPyeEHjytD1DEZ-En17E';

  static Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json;charset=utf-8',
  };

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

  Future<Map<String, dynamic>?> getTVDetails(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tv/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMovieDetails(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTVImages(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tv/$id/images'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMovieImages(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/$id/images'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}
