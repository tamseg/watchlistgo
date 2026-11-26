const PRECISION_RANK = { year: 1, month: 2, day: 3 };
const SEASON_FORMATS = new Set(['TV', 'TV_SHORT', 'ONA', null, undefined]);
const FILM_MIN_RUNTIME = 70;
const MISMATCH_TOLERANCE = 2;
const pad = n => String(n).padStart(2, '0');

function fuzzyDate(d) {
  if (!d?.year) return { date: null, precision: null };
  if (!d.month) return { date: `${d.year}`, precision: 'year' };
  if (!d.day) return { date: `${d.year}-${pad(d.month)}`, precision: 'month' };
  return { date: `${d.year}-${pad(d.month)}-${pad(d.day)}`, precision: 'day' };
}

const mediaTitle = m => m.title?.english ?? null;

function tmdbReleasedEpisodes(details) {
  const last = details.last_episode_to_air;
  if (!last) return 0;
  const earlier = (details.seasons ?? [])
    .filter(s => s.season_number > 0 && s.season_number < last.season_number)
    .reduce((sum, s) => sum + s.episode_count, 0);
  return earlier + last.episode_number;
}

function summarizeAnilist(nodes) {
  if (!nodes) return null;
  const upcoming = nodes.filter(n => n.status === 'NOT_YET_RELEASED');
  const season = upcoming.find(n => SEASON_FORMATS.has(n.format));
  const film = upcoming.find(n => n.format === 'MOVIE');
  return {
    season: season
      ? { title: mediaTitle(season), ...fuzzyDate(season.startDate) }
      : null,
    film: film
      ? { title: mediaTitle(film), ...fuzzyDate(film.startDate) }
      : null,
  };
}

const morePrecise = (a, b) =>
  (PRECISION_RANK[a] ?? 0) > (PRECISION_RANK[b] ?? 0);
const isFilm = e =>
  (e.runtime ?? 0) >= FILM_MIN_RUNTIME ||
  /\b(movie|film)\b/i.test(e.name ?? '');

function releasedEpisodes(episodes, now) {
  const nowIso = now.toISOString();
  const today = nowIso.slice(0, 10);
  return episodes.filter(
    e =>
      e.type === 'regular' &&
      (e.airstamp ? e.airstamp <= nowIso : !!e.airdate && e.airdate <= today),
  ).length;
}

function deriveSeriesInfo({ details, shows, anilist, now }) {
  const nowIso = now.toISOString();
  const today = nowIso.slice(0, 10);
  const when = e => e.airstamp ?? e.airdate ?? null;
  const aired = e =>
    e.airstamp ? e.airstamp <= nowIso : !!e.airdate && e.airdate <= today;

  const ordered = [...shows].sort((a, b) =>
    (a.show.premiered ?? '').localeCompare(b.show.premiered ?? ''),
  );
  const primary = ordered.at(-1);
  const regular = ordered.flatMap(s =>
    s.episodes
      .filter(e => e.type === 'regular')
      .map(e => ({ ...e, tvmazeId: s.show.id })),
  );
  const released = regular
    .filter(aired)
    .sort((a, b) => when(a).localeCompare(when(b)));
  const upcoming = regular
    .filter(e => !aired(e) && when(e))
    .sort((a, b) => when(a).localeCompare(when(b)));

  const primaryReleased = released.filter(e => e.tvmazeId === primary?.show.id);
  const currentSeason = Math.max(0, ...primaryReleased.map(e => e.season));
  const futureSeasons = (primary?.seasons ?? [])
    .filter(
      s =>
        s.number > currentSeason && (!s.premiereDate || s.premiereDate > today),
    )
    .sort((a, b) => a.number - b.number);

  let next = null;
  const nextEpisode = upcoming[0];
  if (nextEpisode) {
    const opensSeason =
      nextEpisode.tvmazeId === primary?.show.id &&
      nextEpisode.season > currentSeason;
    next = {
      kind: opensSeason ? 'season' : 'episode',
      season: nextEpisode.season,
      episode: nextEpisode.number,
      title: null,
      date: when(nextEpisode).slice(0, 10),
      precision: 'day',
    };
  } else if (futureSeasons.length) {
    const s = futureSeasons[0];
    next = {
      kind: 'season',
      season: s.number,
      episode: null,
      title: null,
      date: s.premiereDate ?? null,
      precision: s.premiereDate ? 'day' : null,
    };
  }

  const aniSeason = anilist?.season;
  if (aniSeason && next?.kind !== 'episode') {
    if (!next) {
      next = {
        kind: 'season',
        season: aniSeason.title ? null : currentSeason + 1,
        episode: null,
        title: aniSeason.title,
        date: aniSeason.date,
        precision: aniSeason.precision,
      };
    } else {
      next.title = aniSeason.title;
      if (morePrecise(aniSeason.precision, next.precision)) {
        next.date = aniSeason.date;
        next.precision = aniSeason.precision;
      }
    }
  }

  const tvmazeFilm = ordered
    .flatMap(s => s.episodes)
    .find(e => e.type === 'significant_special' && !aired(e) && isFilm(e));
  const film =
    anilist?.film ??
    (tvmazeFilm
      ? {
          title: tvmazeFilm.name,
          date: tvmazeFilm.airdate ?? null,
          precision: tvmazeFilm.airdate ? 'day' : null,
        }
      : null);

  let state;
  if (next?.kind === 'episode') state = 'airing';
  else if (next?.date) state = 'dated';
  else if (next) state = 'announced';
  else if (primary?.show.status === 'Ended') state = 'ended';
  else if (!primary || primary.show.status === 'To Be Determined')
    state = 'unknown';
  else state = 'returning';

  const seasons = [];
  for (const s of ordered) {
    const bySeason = new Map();
    for (const e of s.episodes.filter(x => x.type === 'regular')) {
      const entry = bySeason.get(e.season) ?? {
        tvmazeId: s.show.id,
        number: e.season,
        episodes: 0,
        released: 0,
      };
      entry.episodes++;
      if (aired(e)) entry.released++;
      bySeason.set(e.season, entry);
    }
    seasons.push(...[...bySeason.values()].sort((a, b) => a.number - b.number));
  }

  const last = released.at(-1);
  const tmdbEpisodes = tmdbReleasedEpisodes(details);
  return {
    tmdbId: details.id,
    name: details.name,
    tvmazeIds: ordered.map(s => s.show.id),
    state,
    next,
    film,
    lastEpisode: last
      ? { season: last.season, episode: last.number, airstamp: when(last) }
      : null,
    seasons,
    mappingWarning: !primary
      ? 'unmapped'
      : tmdbEpisodes > released.length + MISMATCH_TOLERANCE
        ? 'episodeCountMismatch'
        : null,
  };
}

function upcomingReleases({ details, shows, now }) {
  const nowIso = now.toISOString();
  return shows
    .flatMap(s => s.episodes)
    .filter(e => e.type === 'regular' && e.airstamp && e.airstamp > nowIso)
    .map(e => ({
      id: String(e.id),
      tmdbId: details.id,
      season: e.season,
      episode: e.number,
      name: e.name ?? null,
      airstamp: e.airstamp,
    }));
}

function formatDate({ date, precision }) {
  if (!date) return null;
  if (precision === 'year') return date;
  const [y, m, d] = date.split('-').map(Number);
  const options =
    precision === 'day'
      ? { month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC' }
      : { month: 'short', year: 'numeric', timeZone: 'UTC' };
  return new Date(Date.UTC(y, m - 1, d ?? 1)).toLocaleDateString(
    'en-US',
    options,
  );
}

function sameSeason(a, b) {
  if (a.season != null && b.season != null) return a.season === b.season;
  return a.title === b.title;
}

function diffNotifications(prev, next) {
  if (!prev) return [];
  const messages = [];
  const before = prev.next?.kind === 'season' ? prev.next : null;
  const after = next.next?.kind === 'season' ? next.next : null;
  if (after) {
    const label =
      after.season != null
        ? `Season ${after.season}`
        : (after.title ?? 'A new season');
    const date = formatDate(after);
    if (!before || !sameSeason(before, after)) {
      messages.push(date ? `${label} premieres ${date}` : `${label} announced`);
    } else if (after.date && after.date !== before.date) {
      const refined = before.date && after.date.startsWith(before.date);
      messages.push(
        before.date && !refined
          ? `${label} moved to ${date}`
          : `${label} premieres ${date}`,
      );
    }
  }
  if (next.film && next.film.title !== prev.film?.title) {
    const name = next.film.title ? `: ${next.film.title}` : '';
    messages.push(
      after
        ? `A movie is coming${name}`
        : `No new season yet, but a movie is coming${name}`,
    );
  }
  return messages;
}

module.exports = {
  MISMATCH_TOLERANCE,
  releasedEpisodes,
  tmdbReleasedEpisodes,
  deriveSeriesInfo,
  summarizeAnilist,
  upcomingReleases,
  diffNotifications,
  formatDate,
};
