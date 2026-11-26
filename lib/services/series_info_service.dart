import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/series_info.dart';

class SeriesInfoService {
  final FirebaseFirestore _firestore;

  SeriesInfoService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<SeriesInfo?> watch(int tmdbId) => _firestore
      .doc('seriesInfo/$tmdbId')
      .snapshots()
      .map((snap) => snap.exists ? SeriesInfo.fromJson(snap.data()!) : null)
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) => sink.add(null),
        ),
      );
}
