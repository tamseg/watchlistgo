const HOUR = 3600 * 1000;
const HOURLY_NEW_SHOWS = 200;

function grantQuota(stored, wanted, now) {
  const hour = Math.floor(now.getTime() / HOUR);
  const used = stored?.hour === hour ? stored.count : 0;
  const granted = Math.max(0, Math.min(wanted, HOURLY_NEW_SHOWS - used));
  return { granted, quota: { hour, count: used + granted } };
}

async function takeQuota(db, wanted, now = new Date()) {
  const ref = db.doc('limits/newSeries');
  return db.runTransaction(async tx => {
    const stored = (await tx.get(ref)).data();
    const { granted, quota } = grantQuota(stored, wanted, now);
    tx.set(ref, quota);
    return granted;
  });
}

module.exports = { grantQuota, takeQuota, HOURLY_NEW_SHOWS };
