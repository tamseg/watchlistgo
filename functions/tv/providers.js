const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

function throttle(minGapMs) {
  let last = 0;
  return async () => {
    const wait = last + minGapMs - Date.now();
    if (wait > 0) await sleep(wait);
    last = Date.now();
  };
}

async function getJson(url, options = {}, wait = async () => {}) {
  for (let attempt = 0; attempt < 5; attempt++) {
    await wait();
    let res;
    try {
      res = await fetch(url, options);
    } catch (e) {
      if (attempt === 4) throw e;
      await sleep(2000 * (attempt + 1));
      continue;
    }
    if (res.status === 429) {
      await sleep(Number(res.headers.get('retry-after') ?? 5) * 1000);
      continue;
    }
    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`${res.status} ${url}`);
    return res.json();
  }
  throw new Error(`Rate limited: ${url}`);
}

const tvmazeWait = throttle(500);
const anilistWait = throttle(2100);

const tmdb = path =>
  getJson(`https://api.themoviedb.org/3${path}`, {
    headers: { Authorization: `Bearer ${process.env.TMDB_ACCESS_TOKEN}` },
  });

const tvmaze = path => getJson(`https://api.tvmaze.com${path}`, {}, tvmazeWait);

async function anilist(query, variables) {
  const body = await getJson(
    'https://graphql.anilist.co',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ query, variables }),
    },
    anilistWait,
  );
  return body.data;
}

module.exports = { tmdb, tvmaze, anilist };
