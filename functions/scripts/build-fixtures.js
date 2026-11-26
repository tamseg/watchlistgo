const fs = require('fs');
const path = require('path');

const env = fs.readFileSync(path.join(__dirname, '..', '.env'), 'utf8');
process.env.TMDB_ACCESS_TOKEN = env
  .match(/^TMDB_ACCESS_TOKEN=(.*)$/m)[1]
  .trim();

const { resolveSeries } = require('../tv/resolve');

const OVERRIDES = { 30984: [1905, 80375] };

const pick = (obj, keys) =>
  Object.fromEntries(keys.map(k => [k, obj[k] ?? null]));

async function main() {
  const library = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const outDir = path.join(__dirname, '..', 'test', 'fixtures');
  fs.mkdirSync(outDir, { recursive: true });
  const fetchedAt = new Date().toISOString();
  const jobs = [
    ...library.map(({ tmdbId }) => ({ tmdbId, name: tmdbId })),
    ...Object.entries(OVERRIDES).map(([tmdbId, tvmazeIds]) => ({
      tmdbId: Number(tmdbId),
      name: `${tmdbId}-override`,
      override: { tvmazeIds },
    })),
  ];
  for (const { tmdbId, name, override } of jobs) {
    const r = await resolveSeries(tmdbId, { override, withAnilist: true });
    const fixture = {
      fetchedAt,
      details: {
        ...pick(r.details, [
          'id',
          'name',
          'original_name',
          'origin_country',
          'genres',
          'first_air_date',
        ]),
        last_episode_to_air: pick(r.details.last_episode_to_air ?? {}, [
          'season_number',
          'episode_number',
        ]),
        seasons: r.details.seasons.map(s =>
          pick(s, ['season_number', 'episode_count']),
        ),
      },
      shows: r.shows.map(s => ({
        show: pick(s.show, ['id', 'name', 'status', 'premiered']),
        seasons: s.seasons.map(x =>
          pick(x, ['number', 'premiereDate', 'endDate', 'episodeOrder']),
        ),
        episodes: s.episodes.map(x =>
          pick(x, [
            'id',
            'season',
            'number',
            'type',
            'airdate',
            'airstamp',
            'runtime',
            'name',
          ]),
        ),
      })),
      anilistNodes: r.anilistNodes,
    };
    fs.writeFileSync(
      path.join(outDir, `${name}.json`),
      JSON.stringify(fixture),
    );
    const ids = r.shows.map(s => s.show.id).join(',') || 'unmapped';
    const ani = r.anilistNodes ? `, ${r.anilistNodes.length} AniList` : '';
    console.log(`${r.details.name}: ${ids}${ani}`);
  }
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
