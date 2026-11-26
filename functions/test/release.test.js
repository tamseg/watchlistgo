const test = require('node:test');
const assert = require('node:assert/strict');
const { planReleases } = require('../tv/release');

const now = new Date('2026-11-26T12:00:00Z');
const release = (id, tmdbId, season, episode, airstamp) => ({
  id,
  tmdbId,
  season,
  episode,
  airstamp: new Date(airstamp),
});

test('one aired episode gets its own message', () => {
  const { pushes } = planReleases(
    [release('1', 10, 5, 1, '2026-11-26T11:00:00Z')],
    now,
  );
  assert.deepEqual(pushes, [
    { tmdbId: 10, ids: ['1'], body: 'S5E1 is out now' },
  ]);
});

test('episodes of the same show released together are combined', () => {
  const { pushes } = planReleases(
    [
      release('2', 10, 1, 2, '2026-11-26T11:00:00Z'),
      release('1', 10, 1, 1, '2026-11-26T11:00:00Z'),
      release('3', 20, 2, 4, '2026-11-26T11:30:00Z'),
    ],
    now,
  );
  assert.deepEqual(pushes, [
    { tmdbId: 10, ids: ['1', '2'], body: '2 new episodes are out now' },
    { tmdbId: 20, ids: ['3'], body: 'S2E4 is out now' },
  ]);
});

test('episodes that aired over a day ago are not announced', () => {
  const { pushes, staleIds } = planReleases(
    [release('1', 10, 1, 1, '2026-11-24T12:00:00Z')],
    now,
  );
  assert.deepEqual(pushes, []);
  assert.deepEqual(staleIds, ['1']);
});
