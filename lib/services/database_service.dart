import '../models/tracked_title.dart';

abstract class DatabaseService {
  Future<void> deleteUser(String uid);

  Future<void> clearWatchlists(String uid);

  Future<Map<int, MovieRecord>> getMovieRecords(String uid);

  Future<Map<int, SeriesRecord>> getSeriesRecords(String uid);

  Future<void> putMovieRecord(String uid, MovieRecord record);

  Future<void> putSeriesRecord(String uid, SeriesRecord record);

  Future<void> updateMessagingFid({required String uid, required String? fid});
}
