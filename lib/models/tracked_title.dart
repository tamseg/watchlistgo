enum MovieStatus { watchlist, watched }

enum SeriesStatus { following }

DateTime? _readTime(Object? value) => value == null
    ? null
    : DateTime.fromMillisecondsSinceEpoch(value as int, isUtc: true);

int? _writeTime(DateTime? value) => value?.toUtc().millisecondsSinceEpoch;

class MovieRecord {
  final int tmdbId;
  final String? title;
  final MovieStatus status;
  final bool removed;
  final DateTime addedAt;
  final DateTime? updatedAt;
  final DateTime? watchedAt;

  const MovieRecord({
    required this.tmdbId,
    this.title,
    this.status = MovieStatus.watchlist,
    this.removed = false,
    required this.addedAt,
    this.updatedAt,
    this.watchedAt,
  });

  MovieRecord copyWith({
    String? title,
    MovieStatus? status,
    bool? removed,
    DateTime? updatedAt,
    DateTime? Function()? watchedAt,
  }) => MovieRecord(
    tmdbId: tmdbId,
    title: title ?? this.title,
    status: status ?? this.status,
    removed: removed ?? this.removed,
    addedAt: addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    watchedAt: watchedAt != null ? watchedAt() : this.watchedAt,
  );

  Map<String, Object?> toJson() => {
    'tmdbId': tmdbId,
    'title': title,
    'status': status.name,
    'removed': removed,
    'addedAt': _writeTime(addedAt),
    'updatedAt': _writeTime(updatedAt),
    'watchedAt': _writeTime(watchedAt),
  };

  factory MovieRecord.fromJson(Map<String, Object?> json) => MovieRecord(
    tmdbId: json['tmdbId'] as int,
    title: json['title'] as String?,
    status: MovieStatus.values.byName(json['status'] as String),
    removed: json['removed'] as bool? ?? false,
    addedAt: _readTime(json['addedAt'])!,
    updatedAt: _readTime(json['updatedAt']),
    watchedAt: _readTime(json['watchedAt']),
  );
}

class SeriesRecord {
  final int tmdbId;
  final String? title;
  final SeriesStatus status;
  final bool removed;
  final DateTime addedAt;
  final DateTime? updatedAt;

  const SeriesRecord({
    required this.tmdbId,
    this.title,
    this.status = SeriesStatus.following,
    this.removed = false,
    required this.addedAt,
    this.updatedAt,
  });

  SeriesRecord copyWith({
    String? title,
    SeriesStatus? status,
    bool? removed,
    DateTime? updatedAt,
  }) => SeriesRecord(
    tmdbId: tmdbId,
    title: title ?? this.title,
    status: status ?? this.status,
    removed: removed ?? this.removed,
    addedAt: addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'tmdbId': tmdbId,
    'title': title,
    'status': status.name,
    'removed': removed,
    'addedAt': _writeTime(addedAt),
    'updatedAt': _writeTime(updatedAt),
  };

  factory SeriesRecord.fromJson(Map<String, Object?> json) => SeriesRecord(
    tmdbId: json['tmdbId'] as int,
    title: json['title'] as String?,
    status: SeriesStatus.values.byName(json['status'] as String),
    removed: json['removed'] as bool? ?? false,
    addedAt: _readTime(json['addedAt'])!,
    updatedAt: _readTime(json['updatedAt']),
  );
}
