import 'package:flutter_test/flutter_test.dart';
import 'package:watchlistgo/models/series_info.dart';
import 'package:watchlistgo/models/series_status.dart';

SeriesInfo info(Map<String, dynamic> json) => SeriesInfo.fromJson(json);

Map<String, dynamic> season(
  int? number, {
  String? title,
  String? date,
  String? precision,
}) => {
  'kind': 'season',
  'season': number,
  'episode': null,
  'title': title,
  'date': date,
  'precision': precision,
};

const lastEpisode = {
  'season': 5,
  'episode': 16,
  'airstamp': '2013-09-29T00:00:00+00:00',
};

void main() {
  test('formatReleaseDate formats each precision', () {
    String format(String value, DatePrecision p) =>
        formatReleaseDate(ReleaseDate(value, p));
    expect(format('2027-02-17', DatePrecision.day), 'Feb 17, 2027');
    expect(format('2027-10', DatePrecision.month), 'Oct 2027');
    expect(format('2027', DatePrecision.year), '2027');
  });

  group('stripShowName', () {
    test('removes the show name and separator', () {
      expect(
        stripShowName('Chainsaw Man: Shikaku-hen', 'Chainsaw Man'),
        'Shikaku-hen',
      );
      expect(
        stripShowName('SAKAMOTO DAYS Season 2', 'SAKAMOTO DAYS'),
        'Season 2',
      );
    });

    test('ignores punctuation and spacing differences', () {
      expect(
        stripShowName('One Punch Man Season 3 Part 2', 'One-Punch Man'),
        'Season 3 Part 2',
      );
      expect(stripShowName('Dandadan 3rd Season', 'Dan Da Dan'), '3rd Season');
    });

    test('keeps titles that only partly match the name', () {
      expect(stripShowName('Arcane Season 2', 'Arc'), 'Arcane Season 2');
      expect(
        stripShowName('Season 4: The Calamity', 'Bleach'),
        'Season 4: The Calamity',
      );
    });

    test('a title that is only the show name leaves nothing', () {
      expect(stripShowName('Bleach', 'Bleach'), '');
    });
  });

  group('seasonLabel', () {
    SeasonLabel label(String? title, int season, String name) => seasonLabel(
      NextUp(kind: NextKind.season, season: season, title: title),
      name,
    );

    test('uses the number written in the title', () {
      expect(label('One Punch Man Season 3 Part 2', 4, 'One-Punch Man'), (
        label: 'Season 3 Part 2',
        extra: null,
      ));
      expect(label('Dandadan 3rd Season', 3, 'Dan Da Dan'), (
        label: 'Season 3',
        extra: null,
      ));
    });

    test('keeps the rest of the title as extra', () {
      expect(label('Season 4: The Calamity', 4, 'Bleach'), (
        label: 'Season 4',
        extra: 'The Calamity',
      ));
    });

    test('falls back to the counted number', () {
      expect(
        label('Jujutsu Kaisen: Shimetsu Kaiyuu - Kouhen', 4, 'JUJUTSU KAISEN'),
        (label: 'Season 4', extra: 'Shimetsu Kaiyuu - Kouhen'),
      );
      expect(label(null, 3, 'Fallout'), (label: 'Season 3', extra: null));
    });
  });

  group('seriesStatusLine', () {
    test('a dated season shows which season and when', () {
      final line = seriesStatusLine(
        info({
          'state': 'dated',
          'next': season(5, date: '2027-02-17', precision: 'day'),
        }),
        'Invincible',
      );
      expect(line, (label: 'New season', value: 'Season 5 · Feb 17, 2027'));
    });

    test('the card shows the season number, details add the title', () {
      final parsed = info({
        'state': 'announced',
        'next': season(2, title: 'Chainsaw Man: Shikaku-hen'),
      });
      expect(seriesStatusLine(parsed, 'Chainsaw Man'), (
        label: 'New season',
        value: 'Season 2 · TBD',
      ));
      expect(seriesStatusLine(parsed, 'Chainsaw Man', detailed: true), (
        label: 'New season',
        value: 'Season 2 · Shikaku-hen · TBD',
      ));
    });

    test('an airing show shows the next episode', () {
      final line = seriesStatusLine(
        info({
          'state': 'airing',
          'next': {
            'kind': 'episode',
            'season': 3,
            'episode': 4,
            'date': '2027-01-18',
            'precision': 'day',
          },
        }),
        'Show',
      );
      expect(line, (label: 'Next episode', value: 'S3E4 · Jan 18, 2027'));
    });

    test('an ended show shows its last episode', () {
      final line = seriesStatusLine(
        info({'state': 'ended', 'lastEpisode': lastEpisode}),
        'Breaking Bad',
      );
      expect(line, (label: 'Ended', value: 'Last: S5E16 · Sep 29, 2013'));
    });

    test('running and undetermined shows both say nothing is announced', () {
      for (final state in ['returning', 'unknown']) {
        final line = seriesStatusLine(
          info({'state': state, 'lastEpisode': lastEpisode}),
          'Show',
        );
        expect(line.label, 'Nothing announced');
      }
    });

    test('a film without a new season is shown as a new movie', () {
      final line = seriesStatusLine(
        info({
          'state': 'unknown',
          'film': {'title': 'Solo Leveling: Beyond the System'},
        }),
        'Solo Leveling',
      );
      expect(line, (label: 'New movie', value: 'Beyond the System · TBD'));
    });

    test('a new season takes the card over a film', () {
      final parsed = info({
        'state': 'announced',
        'next': season(3),
        'film': {'title': 'The Film'},
      });
      expect(seriesStatusLine(parsed, 'Show').label, 'New season');
      expect(filmLine(parsed, 'Show'), (
        label: 'New movie',
        value: 'The Film · TBD',
      ));
    });
  });

  test('SeriesInfo counts only released seasons and episodes', () {
    final parsed = info({
      'state': 'dated',
      'seasons': [
        {'number': 1, 'episodes': 24, 'released': 24},
        {'number': 2, 'episodes': 23, 'released': 23},
        {'number': 3, 'episodes': 12, 'released': 0},
      ],
    });
    expect(parsed.releasedSeasons, 2);
    expect(parsed.releasedEpisodes, 47);
  });

  test('an unknown state falls back to unknown', () {
    expect(info({'state': 'something'}).state, SeriesState.unknown);
  });
}
