const { FieldValue } = require('firebase-admin/firestore');

const isFollowing = record => !!record && record.removed !== true;

const followChanged = (before, after) =>
  isFollowing(before) !== isFollowing(after);

async function updateFollowerCount(db, tmdbId) {
  const snap = await db
    .collectionGroup('series')
    .where('tmdbId', '==', tmdbId)
    .where('removed', '==', false)
    .count()
    .get();
  await db.doc(`seriesFollowers/${tmdbId}`).set({
    count: snap.data().count,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

async function followedSeriesIds(db) {
  const snap = await db
    .collection('seriesFollowers')
    .where('count', '>', 0)
    .get();
  return snap.docs.map(doc => Number(doc.id));
}

module.exports = {
  isFollowing,
  followChanged,
  updateFollowerCount,
  followedSeriesIds,
};
