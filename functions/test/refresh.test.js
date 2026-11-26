const test = require('node:test');
const assert = require('node:assert/strict');
const { refreshDue, anilistDue, resolveNewFollow } = require('../tv/refresh');

const dbWithInfo = exists => ({
  doc: () => ({ get: async () => ({ exists }) }),
});

test('removing or keeping a show does not resolve it', async () => {
  const db = dbWithInfo(false);
  const following = { removed: false };
  const removed = { removed: true };
  const call = (before, after) =>
    resolveNewFollow({ db, tmdbId: 1, before, after });
  assert.equal(await call(following, removed), false);
  assert.equal(await call(following, undefined), false);
  assert.equal(await call(following, following), false);
});

test('a new show is not resolved once the hourly cap is used up', async () => {
  const resolved = await resolveNewFollow({
    db: dbWithInfo(false),
    tmdbId: 1,
    before: undefined,
    after: { removed: false },
    allowed: async () => false,
  });
  assert.equal(resolved, false);
});

test('a new follow of a known show is not resolved again', async () => {
  const resolved = await resolveNewFollow({
    db: dbWithInfo(true),
    tmdbId: 1,
    before: { removed: true },
    after: { removed: false },
  });
  assert.equal(resolved, false);
});

const now = new Date('2026-11-26T12:00:00Z');
const recent = new Date('2026-11-26T10:00:00Z');
const fresh = {
  tvmazeIds: [1],
  refreshedAt: recent,
  next: null,
  backdropPath: '/b.jpg',
};
const none = new Set();

test('a show seen for the first time is due', () => {
  assert.equal(refreshDue(undefined, none, now), true);
});

test('an unchanged, recently refreshed show is skipped', () => {
  assert.equal(refreshDue(fresh, none, now), false);
});

test('a show TVmaze reports as updated is due', () => {
  assert.equal(refreshDue(fresh, new Set(['1']), now), true);
});

test('a show saved before backdrops were stored is due', () => {
  const { backdropPath, ...old } = fresh;
  assert.equal(refreshDue(old, none, now), true);
});

test('a show with a mapping warning is retried every run', () => {
  const flagged = { ...fresh, mappingWarning: 'episodeCountMismatch' };
  assert.equal(refreshDue(flagged, none, now), true);
});

test('a show whose next date has passed is due', () => {
  const next = { kind: 'episode', date: '2026-11-26', precision: 'day' };
  assert.equal(refreshDue({ ...fresh, next }, none, now), true);
});

test('a show not refreshed for a week is due', () => {
  const old = { ...fresh, refreshedAt: new Date('2026-11-18T12:00:00Z') };
  assert.equal(refreshDue(old, none, now), true);
});

test('anime with an undated announcement checks AniList every run', () => {
  const next = { kind: 'season', date: '2027', precision: 'year' };
  const prev = { anime: true, anilistCheckedAt: recent, next };
  assert.equal(anilistDue(prev, now), true);
});

test('other anime check AniList at most daily', () => {
  const prev = { anime: true, anilistCheckedAt: recent, next: null };
  assert.equal(anilistDue(prev, now), false);
});
