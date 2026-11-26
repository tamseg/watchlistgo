const { tmdb, tvmaze, anilist } = require('./providers');
const { linkCandidates, pickLinkedShows } = require('./link');
const {
  MISMATCH_TOLERANCE,
  releasedEpisodes,
  tmdbReleasedEpisodes,
} = require('./derive');

const MEDIA_FIELDS = `id type format status episodes
  title { romaji english } startDate { year month day }`;
const MEDIA_WITH_RELATIONS = `${MEDIA_FIELDS}
  relations { edges { relationType node { ${MEDIA_FIELDS} } } }`;
const SEASON_FORMATS = ['TV', 'TV_SHORT', 'ONA'];
const MAX_ANILIST_NODES = 30;
const ANILIST_BATCH = 50;

const isAnime = details =>
  (details.origin_country ?? []).includes('JP') &&
  (details.genres ?? []).some(g => g.id === 16);

async function findTvmazeId(externalIds) {
  if (externalIds?.imdb_id) {
    const show = await tvmaze(`/lookup/shows?imdb=${externalIds.imdb_id}`);
    if (show) return { id: show.id, mappedBy: 'imdb' };
  }
  if (externalIds?.tvdb_id) {
    const show = await tvmaze(`/lookup/shows?thetvdb=${externalIds.tvdb_id}`);
    if (show) return { id: show.id, mappedBy: 'tvdb' };
  }
  return null;
}

async function fetchTvmazeShow(id) {
  const embed = 'embed[]=seasons&embed[]=episodeswithspecials';
  const { _embedded: embedded, ...show } = await tvmaze(
    `/shows/${id}?${embed}`,
  );
  return {
    show,
    seasons: embedded?.seasons ?? [],
    episodes: embedded?.episodeswithspecials ?? [],
  };
}

async function linkMissingShows(details, shows, now) {
  const mapped = shows.reduce(
    (sum, s) => sum + releasedEpisodes(s.episodes, now),
    0,
  );
  const missing = tmdbReleasedEpisodes(details) - mapped;
  if (missing <= MISMATCH_TOLERANCE) return [];

  const query = encodeURIComponent(details.name);
  const results = (await tvmaze(`/search/shows?q=${query}`)) ?? [];
  const candidates = [];
  for (const show of linkCandidates(details, shows, results)) {
    const full = await fetchTvmazeShow(show.id);
    candidates.push({
      id: show.id,
      full,
      released: releasedEpisodes(full.episodes, now),
    });
  }
  const ids = pickLinkedShows(missing, candidates) ?? [];
  return candidates.filter(c => ids.includes(c.id)).map(c => c.full);
}

const SEARCH_QUERY = `query ($search: String) {
  Page(perPage: 15) {
    media(search: $search, type: ANIME) { ${MEDIA_WITH_RELATIONS} }
  }
}`;

async function findAnilistRoot(details) {
  const firstYear = Number(details.first_air_date?.slice(0, 4));
  const candidates = new Map();
  for (const search of new Set([details.name, details.original_name])) {
    const data = await anilist(SEARCH_QUERY, { search });
    for (const media of data.Page.media) candidates.set(media.id, media);
  }
  const root = [...candidates.values()].find(
    media =>
      SEASON_FORMATS.includes(media.format) &&
      media.startDate?.year === firstYear &&
      !media.relations.edges.some(
        e =>
          e.relationType === 'PREQUEL' &&
          SEASON_FORMATS.includes(e.node.format),
      ),
  );
  return root?.id ?? null;
}

const BATCH_QUERY = `query ($ids: [Int]) {
  Page(perPage: ${ANILIST_BATCH}) {
    media(id_in: $ids, type: ANIME) { ${MEDIA_WITH_RELATIONS} }
  }
}`;

async function prefetchAnilist(ids, cache, query = anilist) {
  const missing = [...new Set(ids)].filter(id => id && !cache.has(id));
  for (let i = 0; i < missing.length; i += ANILIST_BATCH) {
    const ids = missing.slice(i, i + ANILIST_BATCH);
    const data = await query(BATCH_QUERY, { ids });
    for (const media of data.Page.media) cache.set(media.id, media);
  }
}

const sequelIds = media =>
  media.relations.edges
    .filter(e => e.relationType === 'SEQUEL' && e.node.type === 'ANIME')
    .map(e => e.node.id);

async function prefetchAnilistChains(startIds, cache, query = anilist) {
  const seen = new Set(startIds);
  let level = [...seen];
  while (level.length) {
    await prefetchAnilist(level, cache, query);
    const next = level
      .flatMap(id => (cache.has(id) ? sequelIds(cache.get(id)) : []))
      .filter(id => !seen.has(id));
    next.forEach(id => seen.add(id));
    level = [...new Set(next)];
  }
}

async function fetchAnilistSequels(startId, cache, query = anilist) {
  const nodes = [];
  const seen = new Set([startId]);
  let level = [startId];
  while (level.length && nodes.length < MAX_ANILIST_NODES) {
    await prefetchAnilist(level, cache, query);
    const next = [];
    for (const id of level) {
      const found = cache.get(id);
      if (!found) continue;
      const { relations, ...media } = found;
      nodes.push(media);
      for (const sequel of sequelIds(found)) {
        if (seen.has(sequel)) continue;
        seen.add(sequel);
        next.push(sequel);
      }
    }
    level = next;
  }
  return nodes;
}

function anilistFrontier(nodes) {
  const started = nodes.filter(
    n => n.status === 'FINISHED' || n.status === 'RELEASING',
  );
  const key = n => [
    n.startDate?.year ?? 0,
    n.startDate?.month ?? 0,
    n.startDate?.day ?? 0,
  ];
  started.sort((a, b) => {
    const [x, y] = [key(a), key(b)];
    return x[0] - y[0] || x[1] - y[1] || x[2] - y[2];
  });
  return started.at(-1)?.id ?? null;
}

async function resolveSeries(
  tmdbId,
  {
    previous,
    override,
    withAnilist,
    now = new Date(),
    anilistCache = new Map(),
  },
) {
  const details = await tmdb(`/tv/${tmdbId}?append_to_response=external_ids`);
  if (!details) throw new Error(`TMDB show ${tmdbId} not found`);

  let tvmazeIds = override?.tvmazeIds ?? previous?.tvmazeIds;
  let mappedBy = override?.tvmazeIds ? 'override' : previous?.mappedBy;
  if (!tvmazeIds?.length) {
    const found = await findTvmazeId(details.external_ids);
    tvmazeIds = found ? [found.id] : [];
    mappedBy = found?.mappedBy ?? null;
  }
  const shows = [];
  for (const id of tvmazeIds) shows.push(await fetchTvmazeShow(id));
  if (!override?.tvmazeIds && shows.length) {
    const linked = await linkMissingShows(details, shows, now);
    if (linked.length) {
      shows.push(...linked);
      mappedBy = 'linked';
    }
  }

  const anime = isAnime(details);
  let anilistNodes = null;
  let anilistRootId = previous?.anilistRootId ?? null;
  let anilistFrontierId = previous?.anilistFrontierId ?? null;
  if (anime && withAnilist) {
    anilistRootId ??= await findAnilistRoot(details);
    const start = anilistFrontierId ?? anilistRootId;
    if (start) {
      anilistNodes = await fetchAnilistSequels(start, anilistCache);
      anilistFrontierId = anilistFrontier(anilistNodes) ?? start;
    }
  }

  return {
    details,
    shows,
    mappedBy,
    anime,
    anilistNodes,
    anilistRootId,
    anilistFrontierId,
  };
}

module.exports = {
  resolveSeries,
  isAnime,
  prefetchAnilist,
  prefetchAnilistChains,
  fetchAnilistSequels,
};
