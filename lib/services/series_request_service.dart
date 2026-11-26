import 'package:cloud_functions/cloud_functions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeriesRequestService {
  static const _requestedOnKey = 'seriesRequestedOn';

  final FirebaseFunctions _functions;

  SeriesRequestService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'me-west1');

  Future<void> request(List<int> tmdbIds) async {
    if (tmdbIds.isEmpty) return;
    try {
      await _functions.httpsCallable('requestSeries').call({
        'tmdbIds': tmdbIds,
      });
    } catch (e) {
      debugPrint('Series request failed: $e');
    }
  }

  Future<void> requestDaily(List<int> tmdbIds) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    if (prefs.getString(_requestedOnKey) == today) return;
    await request(tmdbIds);
    await prefs.setString(_requestedOnKey, today);
  }
}
