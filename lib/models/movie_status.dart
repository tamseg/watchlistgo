import 'series_info.dart';
import 'series_status.dart';

final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

StatusLine movieReleaseLine(String? releaseDate, DateTime today) {
  if (releaseDate == null || !_isoDate.hasMatch(releaseDate)) {
    return (label: 'Release date', value: 'TBD');
  }
  final date = formatReleaseDate(ReleaseDate(releaseDate, DatePrecision.day));
  final todayIso = today.toIso8601String().substring(0, 10);
  final upcoming = releaseDate.compareTo(todayIso) >= 0;
  return (label: upcoming ? 'Premieres' : 'Premiered', value: date);
}
