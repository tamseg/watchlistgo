const test = require('node:test');
const assert = require('node:assert/strict');
const { tmdbPath } = require('../tmdb');

test('the three supported requests map to TMDB paths', () => {
  assert.equal(
    tmdbPath({ op: 'search', query: '  dan da dan ' }),
    '/search/multi?query=dan%20da%20dan',
  );
  assert.equal(tmdbPath({ op: 'details', type: 'tv', id: 95479 }), '/tv/95479');
  assert.equal(
    tmdbPath({ op: 'images', type: 'movie', id: 324857 }),
    '/movie/324857/images?include_image_language=en,null',
  );
});

test('a search query cannot inject other parameters', () => {
  assert.equal(
    tmdbPath({ op: 'search', query: 'x&page=2' }),
    '/search/multi?query=x%26page%3D2',
  );
});

test('anything else is rejected', () => {
  assert.equal(tmdbPath({ op: 'search', query: '' }), null);
  assert.equal(tmdbPath({ op: 'search', query: 'a'.repeat(201) }), null);
  assert.equal(tmdbPath({ op: 'details', type: 'person', id: 1 }), null);
  assert.equal(tmdbPath({ op: 'details', type: 'tv', id: '1/credits' }), null);
  assert.equal(tmdbPath({ op: 'details', type: 'tv', id: -1 }), null);
  assert.equal(tmdbPath({ op: 'account', type: 'tv', id: 1 }), null);
  assert.equal(tmdbPath(), null);
});
