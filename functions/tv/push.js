const { getMessaging } = require('firebase-admin/messaging');

const CHANNEL_ID = 'watchlstgo_notifications';
const BATCH_SIZE = 500;

async function followerFids(db, kind, tmdbId, include = () => true) {
  const snap = await db
    .collectionGroup(kind)
    .where('tmdbId', '==', tmdbId)
    .where('removed', '==', false)
    .get();
  const uids = [
    ...new Set(
      snap.docs.filter(d => include(d.data())).map(d => d.ref.parent.parent.id),
    ),
  ];
  if (!uids.length) return [];
  const users = await db.getAll(...uids.map(uid => db.doc(`users/${uid}`)));
  return users.map(u => u.get('fid')).filter(Boolean);
}

const backdropUrl = path =>
  path ? `https://image.tmdb.org/t/p/w500${path}` : null;

async function sendPush({ fids, title, body, type, id, imagePath }) {
  const imageUrl = backdropUrl(imagePath);
  for (let i = 0; i < fids.length; i += BATCH_SIZE) {
    await getMessaging().sendEachForMulticast({
      fids: fids.slice(i, i + BATCH_SIZE),
      notification: { title, body, ...(imageUrl && { imageUrl }) },
      data: { type, id: String(id) },
      android: { notification: { channelId: CHANNEL_ID } },
    });
  }
}

module.exports = { followerFids, sendPush };
