const test = require('node:test');
const assert = require('node:assert/strict');
const {
  prefetchAnilist,
  prefetchAnilistChains,
  fetchAnilistSequels,
} = require('../tv/resolve');

const sequel = id => ({ relationType: 'SEQUEL', node: { id, type: 'ANIME' } });
const media = (id, sequels = []) => ({
  id,
  relations: { edges: sequels.map(sequel) },
});

function fakeAnilist(entries) {
  const calls = [];
  const query = async (_, { ids }) => {
    calls.push(ids);
    return { Page: { media: ids.map(id => entries[id]).filter(Boolean) } };
  };
  return { calls, query };
}

test('entries are fetched in batches of 50', async () => {
  const entries = {};
  for (let id = 1; id <= 120; id++) entries[id] = media(id);
  const { calls, query } = fakeAnilist(entries);
  const cache = new Map();

  await prefetchAnilist(Object.keys(entries).map(Number), cache, query);

  assert.deepEqual(
    calls.map(ids => ids.length),
    [50, 50, 20],
  );
  assert.equal(cache.size, 120);
});

test('cached entries are not fetched again', async () => {
  const { calls, query } = fakeAnilist({ 1: media(1), 2: media(2) });
  const cache = new Map([[1, media(1)]]);

  await prefetchAnilist([1, 2], cache, query);

  assert.deepEqual(calls, [[2]]);
});

test('a sequel chain takes one request per level', async () => {
  const { calls, query } = fakeAnilist({
    1: media(1, [2, 3]),
    2: media(2, [4]),
    3: media(3),
    4: media(4),
  });

  const nodes = await fetchAnilistSequels(1, new Map(), query);

  assert.deepEqual(
    nodes.map(n => n.id),
    [1, 2, 3, 4],
  );
  assert.deepEqual(calls, [[1], [2, 3], [4]]);
});

test('chains of several shows are fetched level by level', async () => {
  const { calls, query } = fakeAnilist({
    1: media(1, [2]),
    2: media(2, [3]),
    3: media(3),
    10: media(10, [11]),
    11: media(11),
  });
  const cache = new Map();

  await prefetchAnilistChains([1, 10], cache, query);
  const chainCalls = calls.length;
  await fetchAnilistSequels(1, cache, query);
  await fetchAnilistSequels(10, cache, query);

  assert.deepEqual(calls, [[1, 10], [2, 11], [3]]);
  assert.equal(calls.length, chainCalls);
});

test('a prefetched start entry needs no request', async () => {
  const { calls, query } = fakeAnilist({});
  const cache = new Map([[1, media(1)]]);

  const nodes = await fetchAnilistSequels(1, cache, query);

  assert.deepEqual(
    nodes.map(n => n.id),
    [1],
  );
  assert.deepEqual(calls, []);
});
