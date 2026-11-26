enum SeriesState { airing, dated, announced, ended, returning, unknown }

enum DatePrecision { day, month, year }

class ReleaseDate {
  final String value;
  final DatePrecision precision;

  const ReleaseDate(this.value, this.precision);

  static ReleaseDate? fromJson(Object? date, Object? precision) {
    if (date is! String || precision is! String) return null;
    final parsed = DatePrecision.values.asNameMap()[precision];
    return parsed == null ? null : ReleaseDate(date, parsed);
  }
}

enum NextKind { season, episode }

class NextUp {
  final NextKind kind;
  final int? season;
  final int? episode;
  final String? title;
  final ReleaseDate? date;

  const NextUp({
    required this.kind,
    this.season,
    this.episode,
    this.title,
    this.date,
  });

  factory NextUp.fromJson(Map<String, dynamic> json) => NextUp(
    kind: json['kind'] == 'episode' ? NextKind.episode : NextKind.season,
    season: (json['season'] as num?)?.toInt(),
    episode: (json['episode'] as num?)?.toInt(),
    title: json['title'] as String?,
    date: ReleaseDate.fromJson(json['date'], json['precision']),
  );
}

class ContinuationFilm {
  final String? title;
  final ReleaseDate? date;

  const ContinuationFilm({this.title, this.date});

  factory ContinuationFilm.fromJson(Map<String, dynamic> json) =>
      ContinuationFilm(
        title: json['title'] as String?,
        date: ReleaseDate.fromJson(json['date'], json['precision']),
      );
}

class LastEpisode {
  final int season;
  final int episode;
  final String? airedOn;

  const LastEpisode({
    required this.season,
    required this.episode,
    this.airedOn,
  });

  factory LastEpisode.fromJson(Map<String, dynamic> json) => LastEpisode(
    season: (json['season'] as num).toInt(),
    episode: (json['episode'] as num).toInt(),
    airedOn: (json['airstamp'] as String?)?.substring(0, 10),
  );
}

class SeasonSummary {
  final int number;
  final int episodes;
  final int released;

  const SeasonSummary({
    required this.number,
    required this.episodes,
    required this.released,
  });

  factory SeasonSummary.fromJson(Map<String, dynamic> json) => SeasonSummary(
    number: (json['number'] as num).toInt(),
    episodes: (json['episodes'] as num).toInt(),
    released: (json['released'] as num).toInt(),
  );
}

class SeriesInfo {
  final SeriesState state;
  final NextUp? next;
  final ContinuationFilm? film;
  final LastEpisode? lastEpisode;
  final List<SeasonSummary> seasons;

  const SeriesInfo({
    required this.state,
    this.next,
    this.film,
    this.lastEpisode,
    this.seasons = const [],
  });

  int get releasedSeasons => seasons.where((s) => s.released > 0).length;

  int get releasedEpisodes => seasons.fold(0, (sum, s) => sum + s.released);

  static Map<String, dynamic>? _map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : null;

  factory SeriesInfo.fromJson(Map<String, dynamic> json) {
    final next = _map(json['next']);
    final film = _map(json['film']);
    final last = _map(json['lastEpisode']);
    return SeriesInfo(
      state:
          SeriesState.values.asNameMap()[json['state']] ?? SeriesState.unknown,
      next: next == null ? null : NextUp.fromJson(next),
      film: film == null ? null : ContinuationFilm.fromJson(film),
      lastEpisode: last == null ? null : LastEpisode.fromJson(last),
      seasons: [
        for (final s in (json['seasons'] as List? ?? const []))
          SeasonSummary.fromJson(_map(s)!),
      ],
    );
  }
}
