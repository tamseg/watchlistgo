import 'package:cloud_firestore/cloud_firestore.dart';
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
    final docSnap = await _firestore.collection('users').doc(uid).get();
    final data = docSnap.data();
    if (data != null && data.containsKey('followedSeriesIds')) {
      return List<int>.from(data['followedSeriesIds']);
    }
    return [];
  }

  @override
  Future<void> addSeries({required String uid, required int seriesId}) async {
    await _firestore.collection('users').doc(uid).set({
      'followedSeriesIds': FieldValue.arrayUnion([seriesId]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removeSeries({required String uid, required int seriesId}) async {
    await _firestore.collection('users').doc(uid).set({
      'followedSeriesIds': FieldValue.arrayRemove([seriesId]),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<int>> getFollowedMoviesIds(String uid) async {
    final docSnap = await _firestore.collection('users').doc(uid).get();
    final data = docSnap.data();
    if (data != null && data.containsKey('followedMoviesIds')) {
      return List<int>.from(data['followedMoviesIds']);
    }
    return [];
  }

  @override
  Future<void> addMovie({required String uid, required int movieId}) async {
    await _firestore.collection('users').doc(uid).set({
      'followedMoviesIds': FieldValue.arrayUnion([movieId]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removeMovie({required String uid, required int movieId}) async {
    await _firestore.collection('users').doc(uid).set({
      'followedMoviesIds': FieldValue.arrayRemove([movieId]),
    }, SetOptions(merge: true));
  }

  Future<void> setFollowedSeriesIds({required String uid, required List<int> ids}) async {
    await _firestore.collection('users').doc(uid).set({
      'followedSeriesIds': ids.isEmpty ? FieldValue.delete() : ids,
    }, SetOptions(merge: true));
  }

  Future<void> setFollowedMoviesIds({required String uid, required List<int> ids}) async {
    await _firestore.collection('users').doc(uid).set({
      'followedMoviesIds': ids.isEmpty ? FieldValue.delete() : ids,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateFcmToken({required String uid, required String? token}) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> clearWatchlists(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.update({
        'followedSeriesIds': FieldValue.delete(),
        'followedMoviesIds': FieldValue.delete(),
      });
    }
  }
}
