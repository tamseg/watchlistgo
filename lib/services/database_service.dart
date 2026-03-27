abstract class DatabaseService {
  Future<void> createUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  });

  Future<Map<String, dynamic>?> getUser(String uid);

  Future<void> updateUser({
    required String uid,
    String? displayName,
    String? photoUrl,
  });

  Future<void> deleteUser(String uid);

  Future<List<int>> getFollowedSeriesIds(String uid);

  Future<void> addSeries({required String uid, required int seriesId});

  Future<void> removeSeries({required String uid, required int seriesId});

  Future<List<int>> getFollowedMoviesIds(String uid);

  Future<void> addMovie({required String uid, required int movieId});

  Future<void> removeMovie({required String uid, required int movieId});
}
