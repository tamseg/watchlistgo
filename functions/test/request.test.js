const test = require('node:test');
const assert = require('node:assert/strict');
const { validIds } = require('../tv/request');
const { grantQuota, HOURLY_NEW_SHOWS } = require('../tv/quota');

const now = new Date('2026-11-26T12:30:00Z');
const thisHour = Math.floor(now.getTime() / 3600000);

test('only positive whole numbers are accepted, once each', () => {
  assert.deepEqual(validIds([1, 2, 2, -3, 0, 1.5, '4', null]), [1, 2]);
  assert.deepEqual(validIds('1,2'), []);
  assert.equal(
    validIds(Array.from({ length: 900 }, (_, i) => i + 1)).length,
    500,
  );
});

test('a new hour starts with the full quota', () => {
  const { granted, quota } = grantQuota(
    { hour: thisHour - 1, count: 199 },
    10,
    now,
  );
  assert.equal(granted, 10);
  assert.deepEqual(quota, { hour: thisHour, count: 10 });
});

test('the quota is shared within the hour', () => {
  const stored = { hour: thisHour, count: HOURLY_NEW_SHOWS - 3 };
  const { granted, quota } = grantQuota(stored, 10, now);
  assert.equal(granted, 3);
  assert.equal(quota.count, HOURLY_NEW_SHOWS);
});

test('nothing is granted once the hourly cap is reached', () => {
  const stored = { hour: thisHour, count: HOURLY_NEW_SHOWS };
  assert.equal(grantQuota(stored, 5, now).granted, 0);
});
