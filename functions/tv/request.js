const { resolveNewFollow } = require('./refresh');
const { takeQuota } = require('./quota');

const HOUR = 3600 * 1000;
const MAX_IDS = 500;
const MAX_NEW_PER_CALL = 10;
const REQUEST_REFRESH_AGE = 20 * HOUR;

function validIds(value) {
  if (!Array.isArray(value)) return [];
  const ids = value.filter(id => Number.isInteger(id) && id > 0);
  return [...new Set(ids)].slice(0, MAX_IDS);
}

async function requestSeries({
  db,
  tmdbIds,
  now = new Date(),
  log = console.log,
}) {
  const ids = validIds(tmdbIds);
  if (!ids.length) return { resolved: 0, deferred: 0 };

  const infos = await db.getAll(...ids.map(id => db.doc(`seriesInfo/${id}`)));
  const requests = await db.getAll(
    ...ids.map(id => db.doc(`seriesRequests/${id}`)),
  );
  const batch = db.batch();
  let touched = 0;
  ids.forEach((_, i) => {
    const last = requests[i].get('requestedAt')?.toDate();
    if (last && now - last < REQUEST_REFRESH_AGE) return;
    batch.set(requests[i].ref, { requestedAt: now });
    touched++;
  });
  if (touched) await batch.commit();

  const missing = ids.filter((_, i) => !infos[i].exists);
  const wanted = Math.min(missing.length, MAX_NEW_PER_CALL);
  const granted = wanted ? await takeQuota(db, wanted, now) : 0;
  let resolved = 0;
  for (const tmdbId of missing.slice(0, granted)) {
    try {
      const after = { removed: false };
      if (await resolveNewFollow({ db, tmdbId, after, now })) resolved++;
    } catch (e) {
      log(`Failed to resolve requested series ${tmdbId}: ${e.message}`);
    }
  }
  return { resolved, deferred: missing.length - resolved };
}

module.exports = { requestSeries, validIds };
