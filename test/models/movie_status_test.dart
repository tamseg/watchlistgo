import 'package:flutter_test/flutter_test.dart';
import 'package:watchlistgo/models/movie_status.dart';

void main() {
  final today = DateTime(2026, 11, 26);

  test('a future movie premieres', () {
    expect(movieReleaseLine('2026-12-16', today), (
      label: 'Premieres',
      value: 'Dec 16, 2026',
    ));
  });

  test('a movie releasing today still premieres', () {
    expect(movieReleaseLine('2026-11-26', today).label, 'Premieres');
  });

  test('a released movie premiered', () {
    expect(movieReleaseLine('2026-03-05', today), (
      label: 'Premiered',
      value: 'Mar 5, 2026',
    ));
  });

  test('a movie without a release date is TBD', () {
    for (final date in [null, '', '2027']) {
      expect(movieReleaseLine(date, today), (
        label: 'Release date',
        value: 'TBD',
      ));
    }
  });
}
