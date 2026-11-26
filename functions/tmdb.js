const { HttpsError } = require('firebase-functions/v2/https');
const { tmdb } = require('./tv/providers');

const TYPES = ['tv', 'movie'];
const MAX_QUERY = 200;

function tmdbPath({ op, type, id, query } = {}) {
  if (op === 'search') {
    const text = typeof query === 'string' ? query.trim() : '';
    if (!text || text.length > MAX_QUERY) return null;
    return `/search/multi?query=${encodeURIComponent(text)}`;
  }
  if (!TYPES.includes(type) || !Number.isInteger(id) || id <= 0) return null;
  if (op === 'details') return `/${type}/${id}`;
  if (op === 'images') {
    return `/${type}/${id}/images?include_image_language=en,null`;
  }
  return null;
}

async function proxyTmdb(data) {
  const path = tmdbPath(data ?? {});
  if (!path) throw new HttpsError('invalid-argument', 'Unsupported request');
  const result = await tmdb(path);
  if (!result) throw new HttpsError('not-found', 'Not found on TMDB');
  return result;
}

module.exports = { tmdbPath, proxyTmdb };
