import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tracked_title.dart';

Timestamp? _toTimestamp(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value.toUtc());

DateTime? _fromTimestamp(Object? value) =>
    value is Timestamp ? value.toDate().toUtc() : null;

Map<String, Object?> movieToFirestore(MovieRecord record) => {
  'tmdbId': record.tmdbId,
  'title': record.title,
  'status': record.status.name,
  'removed': record.removed,
  'addedAt': _toTimestamp(record.addedAt),
  'watchedAt': _toTimestamp(record.watchedAt),
};

MovieRecord movieFromFirestore(Map<String, dynamic> data) => MovieRecord(
  tmdbId: data['tmdbId'] as int,
  title: data['title'] as String?,
  status: MovieStatus.values.byName(data['status'] as String),
  removed: data['removed'] as bool? ?? false,
  addedAt: _fromTimestamp(data['addedAt'])!,
  updatedAt: _fromTimestamp(data['updatedAt']),
  watchedAt: _fromTimestamp(data['watchedAt']),
);

Map<String, Object?> seriesToFirestore(SeriesRecord record) => {
  'tmdbId': record.tmdbId,
  'title': record.title,
  'status': record.status.name,
  'removed': record.removed,
  'addedAt': _toTimestamp(record.addedAt),
};

SeriesRecord seriesFromFirestore(Map<String, dynamic> data) => SeriesRecord(
  tmdbId: data['tmdbId'] as int,
  title: data['title'] as String?,
  status: SeriesStatus.values.byName(data['status'] as String),
  removed: data['removed'] as bool? ?? false,
  addedAt: _fromTimestamp(data['addedAt'])!,
  updatedAt: _fromTimestamp(data['updatedAt']),
);
