const test = require('node:test');
const assert = require('node:assert/strict');
const { refreshDue, anilistDue } = require('../tv/refresh');

const now = new Date('2026-11-26T12:00:00Z');
const recent = new Date('2026-11-26T10:00:00Z');
const fresh = { tvmazeIds: [1], refreshedAt: recent, next: null };
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
