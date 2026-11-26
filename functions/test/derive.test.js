const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const {
  deriveSeriesInfo,
  summarizeAnilist,
  diffNotifications,
  seasonLabel,
} = require('../tv/derive');

function derive(name, onlyTvmazeId) {
  const file = path.join(__dirname, 'fixtures', `${name}.json`);
  const f = JSON.parse(fs.readFileSync(file, 'utf8'));
  return deriveSeriesInfo({
    details: f.details,
    shows: f.shows.filter(s => !onlyTvmazeId || s.show.id === onlyTvmazeId),
    anilist: summarizeAnilist(f.anilistNodes),
    now: new Date(f.fetchedAt),
  });
}

const EXPECTED = {
  1396: { state: 'ended' },
  1399: { state: 'ended' },
  94605: { state: 'ended' },
  74204: { state: 'ended' },
  76479: { state: 'ended' },
  97645: { state: 'ended' },
  65930: { state: 'ended' },
  205715: { state: 'ended' },
  30984: { state: 'ended' },
  95557: { state: 'dated', date: '2027-02-17', precision: 'day' },
  207332: { state: 'dated', season: 2, precision: 'day' },
  63926: { state: 'dated', date: '2027-01', precision: 'month' },
  207784: { state: 'dated', date: '2027-10', precision: 'month' },
  240411: { state: 'dated', date: '2027', precision: 'year' },
  100088: { state: 'announced', season: 3 },
  224372: { state: 'announced', season: 2 },
  60625: { state: 'announced', season: 10 },
  94997: { state: 'announced', season: 4 },
  60574: { state: 'announced', season: 7 },
  106379: { state: 'announced', season: 3 },
  225171: { state: 'announced', season: 2 },
  95479: { state: 'announced' },
  114410: { state: 'announced' },
  207468: { state: 'announced', season: 3, film: true },
  127532: { state: 'announced', season: 3, film: true },
  105248: { state: 'unknown' },
  280110: { state: 'unknown' },
  290295: { state: 'unknown' },
  86831: { state: 'unknown' },
  261579: { state: 'returning' },
};

for (const [name, expected] of Object.entries(EXPECTED)) {
  test(`${name} derives ${expected.state}`, () => {
    const info = derive(name);
    assert.equal(info.state, expected.state, info.name);
    if (expected.season) assert.equal(info.next.season, expected.season);
    if (expected.date) assert.equal(info.next.date, expected.date);
    if (expected.precision) {
      assert.equal(info.next.precision, expected.precision);
    }
    if (expected.film !== undefined) {
      assert.equal(!!info.film, expected.film, info.name);
    }
  });
}

test('Jujutsu Kaisen has three TVmaze seasons', () => {
  const seasons = derive(95479).seasons.map(s => s.episodes);
  assert.deepEqual(seasons, [24, 23, 12]);
});

test('upcoming anime seasons get a readable label', () => {
  assert.equal(derive(95479).next.season, 4);
  assert.equal(derive(114410).next.season, 2);
  assert.equal(derive(63926).next.title, 'One Punch Man Season 3 Part 2');
});

test('anime seasons without an English title use the Japanese one', () => {
  const info = derive(95479);
  assert.equal(info.next.title, 'Jujutsu Kaisen: Shimetsu Kaiyuu - Kouhen');
  assert.deepEqual(diffNotifications({ next: null }, info), [
    'Season 4 (Shimetsu Kaiyuu - Kouhen) announced',
  ]);
});

test('season labels prefer the number written in the title', () => {
  const label = (title, season, name) => seasonLabel({ title, season }, name);
  assert.deepEqual(label('One Punch Man Season 3 Part 2', 4, 'One-Punch Man'), {
    label: 'Season 3 Part 2',
    extra: null,
  });
  assert.deepEqual(label('Dandadan 3rd Season', 3, 'Dan Da Dan'), {
    label: 'Season 3',
    extra: null,
  });
  assert.deepEqual(label('SAKAMOTO DAYS Season 2', 2, 'SAKAMOTO DAYS'), {
    label: 'Season 2',
    extra: null,
  });
  assert.deepEqual(label('Season 4: The Calamity', 4, 'Bleach'), {
    label: 'Season 4',
    extra: 'The Calamity',
  });
  assert.deepEqual(label('Chainsaw Man: Shikaku-hen', 2, 'Chainsaw Man'), {
    label: 'Season 2',
    extra: 'Shikaku-hen',
  });
  assert.deepEqual(label('Bleach', 2, 'Bleach'), {
    label: 'Season 2',
    extra: null,
  });
  assert.deepEqual(label(null, 3, 'Fallout'), {
    label: 'Season 3',
    extra: null,
  });
});

test('a TVmaze season name comes first, with its season number', () => {
  const info = deriveSeriesInfo({
    details: { id: 1, name: 'Show', seasons: [] },
    shows: [
      {
        show: { id: 9, status: 'Running', premiered: '2020-01-01' },
        seasons: [
          { number: 1, name: '', premiereDate: '2020-01-01' },
          { number: 2, name: 'The Calamity', premiereDate: null },
        ],
        episodes: [
          {
            id: 1,
            season: 1,
            number: 1,
            type: 'regular',
            airdate: '2020-01-01',
          },
        ],
      },
    ],
    anilist: { season: { title: 'Show 2nd Season', date: '2027' } },
    now: new Date('2026-11-26T12:00:00Z'),
  });
  assert.equal(info.next.title, 'Season 2: The Calamity');
});

test('a TVmaze season name made of digits is ignored', () => {
  const info = derive(207332);
  assert.equal(info.next.title, 'SAKAMOTO DAYS Season 2');
});

test('adding a title to a known season does not notify again', () => {
  const before = show(season(4, null, null));
  const after = show({ ...season(4, null, null), title: 'Part 2' });
  assert.deepEqual(diffNotifications(before, after), []);
});

test('a show with listed future episodes is not flagged', () => {
  assert.equal(derive(95557).mappingWarning, null);
});

test('Bleach mapped to one TVmaze show is flagged', () => {
  assert.equal(derive(30984, 1905).mappingWarning, 'episodeCountMismatch');
});

test('Bleach with both TVmaze shows has every episode', () => {
  const info = derive(30984);
  const total = info.seasons.reduce((sum, s) => sum + s.released, 0);
  assert.equal(total, 416);
  assert.equal(info.mappingWarning, null);
});

const show = next => ({ name: 'Show', next, film: null });
const season = (n, date, precision) => ({
  kind: 'season',
  season: n,
  title: null,
  date,
  precision,
});

test('no notifications the first time a show is seen', () => {
  assert.deepEqual(diffNotifications(undefined, show(season(2))), []);
});

test('a newly announced season notifies', () => {
  const messages = diffNotifications(show(null), show(season(2)));
  assert.deepEqual(messages, ['Season 2 announced']);
});

test('a new date notifies with the date', () => {
  const before = show(season(2, null, null));
  const after = show(season(2, '2027-01-18', 'day'));
  assert.deepEqual(diffNotifications(before, after), [
    'Season 2 premieres on Jan 18, 2027',
  ]);
});

test('a more precise date is not reported as moved', () => {
  const before = show(season(2, '2027', 'year'));
  const after = show(season(2, '2027-10', 'month'));
  assert.deepEqual(diffNotifications(before, after), [
    'Season 2 premieres in Oct 2027',
  ]);
});

test('a changed date is reported as moved', () => {
  const before = show(season(2, '2027-01-18', 'day'));
  const after = show(season(2, '2027-02-01', 'day'));
  assert.deepEqual(diffNotifications(before, after), [
    'Season 2 moved to Feb 1, 2027',
  ]);
});

test('an unchanged show does not notify', () => {
  const info = show(season(2, '2027-01-18', 'day'));
  assert.deepEqual(diffNotifications(info, info), []);
});

test('a continuation film without a new season notifies', () => {
  const after = { ...show(null), film: { title: 'The Movie' } };
  assert.deepEqual(diffNotifications(show(null), after), [
    'No new season yet, but a movie is coming: The Movie',
  ]);
});

test('a known film whose title changes does not notify again', () => {
  const film = title => ({ ...show(null), film: { id: 'anilist:1', title } });
  assert.deepEqual(diffNotifications(film(null), film('Kanketsu-hen')), []);
  assert.deepEqual(diffNotifications(film('Kanketsu-hen'), film('Final')), []);
});

test('a known film stored before films had IDs does not notify', () => {
  const before = { ...show(null), film: { title: null } };
  const after = { ...show(null), film: { id: 'anilist:1', title: 'Film' } };
  assert.deepEqual(diffNotifications(before, after), []);
});

test('a different film notifies', () => {
  const before = { ...show(null), film: { id: 'anilist:1', title: 'One' } };
  const after = { ...show(null), film: { id: 'anilist:2', title: 'Two' } };
  assert.deepEqual(diffNotifications(before, after), [
    'No new season yet, but a movie is coming: Two',
  ]);
});
