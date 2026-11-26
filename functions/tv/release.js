const { Timestamp } = require('firebase-admin/firestore');
const { followerFids, sendPush } = require('./push');

const STALE_AFTER = 24 * 3600 * 1000;

function releaseMessage(episodes) {
  if (episodes.length > 1) return `${episodes.length} new episodes are out now`;
  const [e] = episodes;
  return `S${e.season}E${e.episode} is out now`;
}

function planReleases(releases, now) {
  const stale = releases.filter(r => now - r.airstamp > STALE_AFTER);
  const byShow = new Map();
  for (const r of releases.filter(r => !stale.includes(r))) {
    byShow.set(r.tmdbId, [...(byShow.get(r.tmdbId) ?? []), r]);
  }
  const pushes = [...byShow].map(([tmdbId, episodes]) => {
    episodes.sort((a, b) => a.season - b.season || a.episode - b.episode);
    return {
      tmdbId,
      ids: episodes.map(e => e.id),
      body: releaseMessage(episodes),
    };
  });
  return { pushes, staleIds: stale.map(r => r.id) };
}

async function releaseEpisodes({ db, now = new Date(), log = console.log }) {
  const snap = await db
    .collection('episodeReleases')
    .where('notified', '==', false)
    .where('airstamp', '<=', Timestamp.fromDate(now))
    .get();
  if (snap.empty) return;

  const releases = snap.docs.map(d => ({
    id: d.id,
    ...d.data(),
    airstamp: d.get('airstamp').toDate(),
  }));
  const { pushes, staleIds } = planReleases(releases, now);
  const done = [...staleIds];
  for (const push of pushes) {
    try {
      const info = (await db.doc(`seriesInfo/${push.tmdbId}`).get()).data();
      const fids = await followerFids(db, 'series', push.tmdbId);
      if (fids.length) {
        await sendPush({
          fids,
          title: `📺 ${info?.name ?? 'New episode'}`,
          body: push.body,
          type: 'tv',
          id: push.tmdbId,
          imagePath: info?.backdropPath,
        });
      }
      done.push(...push.ids);
      log(`${info?.name ?? push.tmdbId}: ${push.body} (${fids.length})`);
    } catch (e) {
      log(`Failed to announce releases of ${push.tmdbId}: ${e.message}`);
    }
  }
  if (!done.length) return;
  const batch = db.batch();
  for (const id of done) {
    batch.update(db.doc(`episodeReleases/${id}`), { notified: true });
  }
  await batch.commit();
}

module.exports = { planReleases, releaseMessage, releaseEpisodes };
