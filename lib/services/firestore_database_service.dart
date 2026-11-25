import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tracked_title.dart';
import 'database_service.dart';
import 'firestore_records.dart';

class FirestoreDatabaseService implements DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _batchLimit = 450;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _movies(String uid) =>
      _user(uid).collection('movies');

  CollectionReference<Map<String, dynamic>> _series(String uid) =>
      _user(uid).collection('series');

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _serverDocs(
    CollectionReference<Map<String, dynamic>> collection,
  ) async =>
      (await collection.get(const GetOptions(source: Source.server))).docs;

  Future<void> _inBatches<T>(
    List<T> items,
    void Function(WriteBatch batch, T item) write,
  ) async {
    for (var i = 0; i < items.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final item in items.skip(i).take(_batchLimit)) {
        write(batch, item);
      }
      await batch.commit();
    }
  }

  @override
  Future<Map<int, MovieRecord>> getMovieRecords(String uid) async => {
    for (final doc in await _serverDocs(_movies(uid)))
      int.parse(doc.id): movieFromFirestore(doc.data()!),
  };

  @override
  Future<Map<int, SeriesRecord>> getSeriesRecords(String uid) async => {
    for (final doc in await _serverDocs(_series(uid)))
      int.parse(doc.id): seriesFromFirestore(doc.data()!),
  };

  @override
  Future<void> putMovieRecord(String uid, MovieRecord record) =>
      _movies(uid).doc('${record.tmdbId}').set({
        ...movieToFirestore(record),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> putSeriesRecord(String uid, SeriesRecord record) =>
      _series(uid).doc('${record.tmdbId}').set({
        ...seriesToFirestore(record),
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
    for (final collection in [_movies(uid), _series(uid)]) {
      await _inBatches(
        await _serverDocs(collection),
        (batch, doc) => batch.delete(doc.reference),
      );
    }
    await _user(uid).delete();
  }

  @override
  Future<List<int>> getFollowedSeriesIds(String uid) async {
    final docSnap = await _firestore
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
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
  Future<void> removeSeries({
    required String uid,
    required int seriesId,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'followedSeriesIds': FieldValue.arrayRemove([seriesId]),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<int>> getFollowedMoviesIds(String uid) async {
    final docSnap = await _firestore
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
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

  @override
  Future<void> addFollowedIds({
    required String uid,
    required List<int> seriesIds,
    required List<int> movieIds,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      if (seriesIds.isNotEmpty)
        'followedSeriesIds': FieldValue.arrayUnion(seriesIds),
      if (movieIds.isNotEmpty)
        'followedMoviesIds': FieldValue.arrayUnion(movieIds),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateMessagingFid({
    required String uid,
    required String? fid,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'fid': fid ?? FieldValue.delete(),
      'fcmToken': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> clearWatchlists(String uid) async {
    for (final collection in [_movies(uid), _series(uid)]) {
      final active = (await _serverDocs(
        collection,
      )).where((doc) => doc.data()?['removed'] != true).toList();
      await _inBatches(
        active,
        (batch, doc) => batch.update(doc.reference, {
          'removed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );
    }

    final docRef = _user(uid);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.update({
        'followedSeriesIds': FieldValue.delete(),
        'followedMoviesIds': FieldValue.delete(),
      });
    }
  }
}
