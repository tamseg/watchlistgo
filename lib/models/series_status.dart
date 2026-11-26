import 'series_info.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

final _alphanumeric = RegExp(r'[a-z0-9]');
final _separators = RegExp(r'^[\s:\-–—·]+|[\s:\-–—·]+$');
const _part = r'(?:\s+part\s+(\d+))?';
final _seasonPhrase = RegExp(
  'season\\s+(\\d+)$_part|(\\d+)(?:st|nd|rd|th)\\s+season$_part',
  caseSensitive: false,
);

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String formatReleaseDate(ReleaseDate date) {
  final parts = date.value.split('-').map(int.parse).toList();
  return switch (date.precision) {
    DatePrecision.year => '${parts[0]}',
    DatePrecision.month => '${_months[parts[1] - 1]} ${parts[0]}',
    DatePrecision.day => '${_months[parts[1] - 1]} ${parts[2]}, ${parts[0]}',
  };
}

String stripShowName(String title, String showName) {
  final name = _normalize(showName);
  if (name.isEmpty) return title;
  if (_normalize(title) == name) return '';
  final lower = title.toLowerCase();
  var matched = 0;
  var i = 0;
  while (i < lower.length && matched < name.length) {
    if (_alphanumeric.hasMatch(lower[i])) {
      if (lower[i] != name[matched]) return title;
      matched++;
    }
    i++;
  }
  if (matched < name.length) return title;
  if (i < lower.length && _alphanumeric.hasMatch(lower[i])) return title;
  return title.substring(i).replaceAll(_separators, '');
}

typedef SeasonLabel = ({String label, String? extra});

SeasonLabel seasonLabel(NextUp next, String showName) {
  final title = next.title == null
      ? null
      : stripShowName(next.title!, showName);
  final match = title == null ? null : _seasonPhrase.firstMatch(title);
  var label = next.season != null ? 'Season ${next.season}' : 'New season';
  if (match != null) {
    final number = match.group(1) ?? match.group(3);
    final part = match.group(2) ?? match.group(4);
    label = 'Season $number${part != null ? ' Part $part' : ''}';
  }
  final rest = match != null
      ? title!.replaceFirst(match.group(0)!, '')
      : title ?? '';
  final extra = rest.replaceAll(_separators, '').trim();
  return (label: label, extra: extra.isEmpty ? null : extra);
}

String _when(ReleaseDate? date) =>
    date == null ? 'TBD' : formatReleaseDate(date);

String _lastAired(LastEpisode? last) {
  if (last == null) return 'No episodes yet';
  final code = 'Last: S${last.season}E${last.episode}';
  final aired = last.airedOn;
  if (aired == null) return code;
  return '$code · ${formatReleaseDate(ReleaseDate(aired, DatePrecision.day))}';
}

typedef StatusLine = ({String label, String value});

StatusLine? filmLine(SeriesInfo info, String showName) {
  final film = info.film;
  if (film == null) return null;
  final title = film.title == null ? '' : stripShowName(film.title!, showName);
  final name = title.isEmpty ? 'Movie' : title;
  return (label: 'New movie', value: '$name · ${_when(film.date)}');
}

StatusLine seriesStatusLine(
  SeriesInfo info,
  String showName, {
  bool detailed = false,
}) {
  final next = info.next;
  switch (info.state) {
    case SeriesState.airing:
      return (
        label: 'Next episode',
        value: 'S${next?.season}E${next?.episode} · ${_when(next?.date)}',
      );
    case SeriesState.dated:
    case SeriesState.announced:
      final season = seasonLabel(next!, showName);
      final extra = season.extra;
      final name = detailed && extra != null
          ? '${season.label} · $extra'
          : season.label;
      return (label: 'New season', value: '$name · ${_when(next.date)}');
    case SeriesState.ended:
    case SeriesState.returning:
    case SeriesState.unknown:
      final film = filmLine(info, showName);
      if (film != null) return film;
      return (
        label: info.state == SeriesState.ended ? 'Ended' : 'Nothing announced',
        value: _lastAired(info.lastEpisode),
      );
  }
}

String seriesStateName(SeriesState state) => switch (state) {
  SeriesState.airing => 'Airing',
  SeriesState.dated || SeriesState.announced => 'New season',
  SeriesState.ended => 'Ended',
  SeriesState.returning || SeriesState.unknown => 'Nothing announced',
};
