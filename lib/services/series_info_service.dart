import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/series_info.dart';

enum SeriesInfoStatus { loading, ready, unavailable }

typedef SeriesInfoState = ({SeriesInfoStatus status, SeriesInfo? info});

const loadingSeriesInfo = (status: SeriesInfoStatus.loading, info: null);
const unavailableSeriesInfo = (
  status: SeriesInfoStatus.unavailable,
  info: null,
);

class SeriesInfoService {
  final FirebaseFirestore _firestore;

  SeriesInfoService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<SeriesInfoState> watch(int tmdbId) => _firestore
      .doc('seriesInfo/$tmdbId')
      .snapshots()
      .map<SeriesInfoState>(
        (snap) => snap.exists
            ? (
                status: SeriesInfoStatus.ready,
                info: SeriesInfo.fromJson(snap.data()!),
              )
            : loadingSeriesInfo,
      )
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) =>
              sink.add(unavailableSeriesInfo),
        ),
      );
}
