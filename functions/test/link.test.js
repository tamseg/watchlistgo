const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { linkCandidates, pickLinkedShows } = require('../tv/link');
const { releasedEpisodes, tmdbReleasedEpisodes } = require('../tv/derive');

const fixture = name =>
  JSON.parse(
    fs.readFileSync(path.join(__dirname, 'fixtures', `${name}.json`), 'utf8'),
  );

const bleach = fixture(30984);
const linked = fixture('30984-override').shows.find(s => s.show.id === 80375);
const now = new Date(bleach.fetchedAt);
const result = show => ({ score: 1, show });

test('a later show with a matching name is a candidate', () => {
  const candidates = linkCandidates(bleach.details, bleach.shows, [
    result(bleach.shows[0].show),
    result(linked.show),
    result({ id: 31991, name: 'Black', premiered: '2017-10-14' }),
    result({ id: 1, name: 'Bleach Origins', premiered: '1999-01-01' }),
  ]);
  assert.deepEqual(
    candidates.map(c => c.id),
    [80375],
  );
});

test('Bleach links Thousand-Year Blood War by exact episode count', () => {
  const missing =
    tmdbReleasedEpisodes(bleach.details) -
    releasedEpisodes(bleach.shows[0].episodes, now);
  const candidate = {
    id: linked.show.id,
    released: releasedEpisodes(linked.episodes, now),
  };
  assert.deepEqual(pickLinkedShows(missing, [candidate]), [80375]);
});

test('counts that do not add up exactly are not linked', () => {
  assert.equal(pickLinkedShows(50, [{ id: 1, released: 49 }]), null);
});

test('the smallest set of shows that adds up is chosen', () => {
  const candidates = [
    { id: 1, released: 20 },
    { id: 2, released: 30 },
    { id: 3, released: 50 },
  ];
  assert.deepEqual(pickLinkedShows(50, candidates), [3]);
});
