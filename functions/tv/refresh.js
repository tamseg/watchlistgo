const { FieldValue } = require('firebase-admin/firestore');
const { tvmaze } = require('./providers');
const { resolveSeries, prefetchAnilistChains } = require('./resolve');
const { followerFids, sendPush } = require('./push');
const { isFollowing, followedSeriesIds } = require('./followers');
const { takeQuota } = require('./quota');
const {
  deriveSeriesInfo,
  summarizeAnilist,
  upcomingReleases,
  diffNotifications,
} = require('./derive');

const HOUR = 3600 * 1000;
const FULL_REFRESH_AGE = 7 * 24 * HOUR;
const ANILIST_REFRESH_AGE = 20 * HOUR;
const REQUESTED_FOR = 30 * 24 * HOUR;
const READ_BATCH = 300;

const toDate = value => (value?.toDate ? value.toDate() : (value ?? null));
const olderThan = (value, ms, now) => !value || now - toDate(value) > ms;

function anilistDue(prev, now) {
  if (!prev) return true;
  if (!prev.anime) return false;
  const undated = prev.next?.kind === 'season' && prev.next.precision !== 'day';
  return undated || olderThan(prev.anilistCheckedAt, ANILIST_REFRESH_AGE, now);
}

function refreshDue(prev, updatedIds, now) {
  if (!prev) return true;
  const today = now.toISOString().slice(0, 10);
  if (prev.mappingWarning || !('backdropPath' in prev)) return true;
  if (prev.tvmazeIds?.some(id => updatedIds.has(String(id)))) return true;
  if (prev.next?.precision === 'day' && prev.next.date <= today) return true;
  return olderThan(prev.refreshedAt, FULL_REFRESH_AGE, now);
}

async function readSeriesInfo(db, ids) {
  const docs = [];
  for (let i = 0; i < ids.length; i += READ_BATCH) {
    const refs = ids
      .slice(i, i + READ_BATCH)
      .map(id => db.doc(`seriesInfo/${id}`));
    if (refs.length) docs.push(...(await db.getAll(...refs)));
  }
  return docs.map(doc => doc.data());
}

async function requestedSeriesIds(db, now) {
  const since = new Date(now.getTime() - REQUESTED_FOR);
  const snap = await db
    .collection('seriesRequests')
    .where('requestedAt', '>=', since)
    .get();
  return snap.docs.map(doc => Number(doc.id));
}

async function saveReleases(db, releases) {
  if (!releases.length) return;
  const refs = releases.map(r => db.collection('episodeReleases').doc(r.id));
  const existing = await db.getAll(...refs);
  const batch = db.batch();
  releases.forEach((release, i) => {
    const { id, ...data } = release;
    batch.set(
      refs[i],
      existing[i].exists ? data : { ...data, notified: false },
      { merge: true },
    );
  });
  await batch.commit();
}

async function refreshShow({
  db,
  tmdbId,
  prev,
  withAnilist,
  now,
  anilistCache,
}) {
  const ref = db.collection('seriesInfo').doc(String(tmdbId));
  const override = (
    await db.collection('seriesMappingOverrides').doc(String(tmdbId)).get()
  ).data();
  const resolved = await resolveSeries(tmdbId, {
    previous: prev,
    override,
    withAnilist,
    now,
    anilistCache,
  });
  const anilist = resolved.anilistNodes
    ? summarizeAnilist(resolved.anilistNodes)
    : (prev?.anilist ?? null);
  const info = deriveSeriesInfo({
    details: resolved.details,
    shows: resolved.shows,
    anilist,
    now,
  });
  const backdropPath = resolved.details.backdrop_path ?? null;

  await ref.set({
    ...info,
    backdropPath,
    mappedBy: resolved.mappedBy ?? null,
    anime: resolved.anime,
    anilist,
    anilistRootId: resolved.anilistRootId,
    anilistFrontierId: resolved.anilistFrontierId,
    anilistCheckedAt: resolved.anilistNodes
      ? now
      : (prev?.anilistCheckedAt ?? null),
    refreshedAt: now,
    updatedAt: FieldValue.serverTimestamp(),
  });
  await saveReleases(
    db,
    upcomingReleases({ details: resolved.details, shows: resolved.shows, now }),
  );
  return diffNotifications(prev, info).map(body => ({
    tmdbId,
    title: info.name,
    body,
    backdropPath,
  }));
}

async function resolveNewFollow({
  db,
  tmdbId,
  before,
  after,
  now,
  allowed = async () => true,
}) {
  if (!isFollowing(after) || isFollowing(before)) return false;
  const ref = db.doc(`seriesInfo/${tmdbId}`);
  if ((await ref.get()).exists) return false;
  if (!(await allowed())) return false;
  const at = now ?? new Date();
  await refreshShow({
    db,
    tmdbId,
    prev: undefined,
    withAnilist: false,
    now: at,
  });
  const first = (await ref.get()).data();
  if (first?.anime) {
    await refreshShow({ db, tmdbId, prev: first, withAnilist: true, now: at });
  }
  return true;
}

async function refreshSeries({
  db,
  now = new Date(),
  dryRun = true,
  log = console.log,
}) {
  const ids = [
    ...new Set([
      ...(await followedSeriesIds(db)),
      ...(await requestedSeriesIds(db, now)),
    ]),
  ];
  const updates = (await tvmaze('/updates/shows?since=day')) ?? {};
  const updatedIds = new Set(Object.keys(updates));
  const prevs = await readSeriesInfo(db, ids);
  const due = [];
  ids.forEach((tmdbId, i) => {
    const prev = prevs[i];
    const withAnilist = anilistDue(prev, now);
    if (withAnilist || refreshDue(prev, updatedIds, now)) {
      due.push({ tmdbId, prev, withAnilist });
    }
  });

  const anilistCache = new Map();
  const starts = due
    .filter(d => d.withAnilist && d.prev?.anime)
    .map(d => d.prev.anilistFrontierId ?? d.prev.anilistRootId);
  try {
    await prefetchAnilistChains(starts, anilistCache);
  } catch (e) {
    log(`AniList prefetch failed: ${e.message}`);
  }

  const notifications = [];
  let refreshed = 0;
  for (const { tmdbId, prev, withAnilist } of due) {
    try {
      if (!prev && !(await takeQuota(db, 1, now))) continue;
      notifications.push(
        ...(await refreshShow({
          db,
          tmdbId,
          prev,
          withAnilist,
          now,
          anilistCache,
        })),
      );
      refreshed++;
    } catch (e) {
      log(`Failed to refresh series ${tmdbId}: ${e.message}`);
    }
  }

  log(`Refreshed ${refreshed} of ${ids.length} followed series.`);
  for (const n of notifications) {
    if (dryRun) {
      log(`[dry run] ${n.title}: ${n.body}`);
      continue;
    }
    try {
      const fids = await followerFids(db, 'series', n.tmdbId);
      if (fids.length) {
        await sendPush({
          fids,
          title: `📺 ${n.title}`,
          body: n.body,
          type: 'tv',
          id: n.tmdbId,
          imagePath: n.backdropPath,
        });
      }
      log(`${n.title}: ${n.body} (${fids.length})`);
    } catch (e) {
      log(`Failed to notify ${n.title}: ${e.message}`);
    }
  }
  return notifications;
}

module.exports = {
  refreshSeries,
  resolveNewFollow,
  refreshDue,
  anilistDue,
};
