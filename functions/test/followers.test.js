const test = require('node:test');
const assert = require('node:assert/strict');
const { followChanged } = require('../tv/followers');

const following = { removed: false };
const removed = { removed: true };

test('following or unfollowing changes the count', () => {
  assert.equal(followChanged(undefined, following), true);
  assert.equal(followChanged(removed, following), true);
  assert.equal(followChanged(following, removed), true);
  assert.equal(followChanged(following, undefined), true);
});

test('other edits of a record leave the count alone', () => {
  assert.equal(followChanged(following, following), false);
  assert.equal(followChanged(removed, removed), false);
  assert.equal(followChanged(removed, undefined), false);
});
