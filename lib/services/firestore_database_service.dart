import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class FirestoreDatabaseService implements DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> createUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      final now = FieldValue.serverTimestamp();
      await docRef.set({
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': now,
        'updatedAt': now,
        'followedSeriesIds': [],
        'followedMoviesIds': [],
      });
    }
  }

  @override
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final docSnap = await _firestore.collection('users').doc(uid).get();
    return docSnap.data();
  }

  @override
  Future<void> updateUser({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _firestore.collection('users').doc(uid).update(updates);
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  @override
  Future<List<int>> getFollowedSeriesIds(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '${uid}_followedSeriesIds';
    final cached = prefs.getStringList(cacheKey);

    if (cached != null) {
      _syncSeriesFromFirestore(uid, prefs, cacheKey);
      return cached.map((e) => int.parse(e)).toList();
    }

    final docSnap = await _firestore.collection('users').doc(uid).get();
    final data = docSnap.data();
    if (data != null && data.containsKey('followedSeriesIds')) {
      final ids = List<int>.from(data['followedSeriesIds']);
      await prefs.setStringList(
        cacheKey,
        ids.map((e) => e.toString()).toList(),
      );
      return ids;
    }
    return [];
  }

  Future<void> _syncSeriesFromFirestore(
    String uid,
    SharedPreferences prefs,
    String cacheKey,
  ) async {
    try {
      final docSnap = await _firestore.collection('users').doc(uid).get();
      final data = docSnap.data();
      if (data != null && data.containsKey('followedSeriesIds')) {
        final ids = List<int>.from(data['followedSeriesIds']);
        await prefs.setStringList(
          cacheKey,
          ids.map((e) => e.toString()).toList(),
        );
      }
    } catch (_) {}
  }

  @override
  Future<void> addSeries({required String uid, required int seriesId}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '${uid}_followedSeriesIds';
    final cached = prefs.getStringList(cacheKey) ?? [];

    if (!cached.contains(seriesId.toString())) {
      cached.add(seriesId.toString());
      await prefs.setStringList(cacheKey, cached);
    }

    await _firestore.collection('users').doc(uid).update({
      'followedSeriesIds': FieldValue.arrayUnion([seriesId]),
    });
  }

  @override
  Future<void> removeSeries({
    required String uid,
    required int seriesId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '${uid}_followedSeriesIds';
    final cached = prefs.getStringList(cacheKey) ?? [];

    if (cached.contains(seriesId.toString())) {
      cached.remove(seriesId.toString());
      await prefs.setStringList(cacheKey, cached);
    }

    await _firestore.collection('users').doc(uid).update({
      'followedSeriesIds': FieldValue.arrayRemove([seriesId]),
    });
  }

  @override
  Future<List<int>> getFollowedMoviesIds(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '${uid}_followedMoviesIds';
    final cached = prefs.getStringList(cacheKey);

    if (cached != null) {
      _syncMoviesFromFirestore(uid, prefs, cacheKey);
      return cached.map((e) => int.parse(e)).toList();
    }

    final docSnap = await _firestore.collection('users').doc(uid).get();
    final data = docSnap.data();
    if (data != null && data.containsKey('followedMoviesIds')) {
      final ids = List<int>.from(data['followedMoviesIds']);
      await prefs.setStringList(
        cacheKey,
        ids.map((e) => e.toString()).toList(),
      );
      return ids;
    }
    return [];
  }

  Future<void> _syncMoviesFromFirestore(
    String uid,
    SharedPreferences prefs,
    String cacheKey,
  ) async {
    try {
      final docSnap = await _firestore.collection('users').doc(uid).get();
      final data = docSnap.data();
      if (data != null && data.containsKey('followedMoviesIds')) {
        final ids = List<int>.from(data['followedMoviesIds']);
        await prefs.setStringList(
          cacheKey,
          ids.map((e) => e.toString()).toList(),
        );
      }
    } catch (_) {}
  }

  @override
  Future<void> addMovie({required String uid, required int movieId}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '${uid}_followedMoviesIds';
    final cached = prefs.getStringList(cacheKey) ?? [];

    if (!cached.contains(movieId.toString())) {
      cached.add(movieId.toString());
      await prefs.setStringList(cacheKey, cached);
    }

    await _firestore.collection('users').doc(uid).update({
      'followedMoviesIds': FieldValue.arrayUnion([movieId]),
    });
  }

  @override
  Future<void> removeMovie({required String uid, required int movieId}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '${uid}_followedMoviesIds';
    final cached = prefs.getStringList(cacheKey) ?? [];

    if (cached.contains(movieId.toString())) {
      cached.remove(movieId.toString());
      await prefs.setStringList(cacheKey, cached);
    }

    await _firestore.collection('users').doc(uid).update({
      'followedMoviesIds': FieldValue.arrayRemove([movieId]),
    });
  }
}
