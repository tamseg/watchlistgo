const { tmdb } = require('./tv/providers');
const { followerFids, sendPush } = require('./tv/push');

const onWatchlist = data => data.status === 'watchlist';

async function watchlistMovieIds(db) {
  const snap = await db
    .collectionGroup('movies')
    .where('removed', '==', false)
    .get();
  const ids = snap.docs
    .filter(d => onWatchlist(d.data()))
    .map(d => Number(d.get('tmdbId') ?? d.id));
  return [...new Set(ids)];
}

async function notifyMovieReleases({
  db,
  now = new Date(),
  log = console.log,
}) {
  const today = now.toISOString().slice(0, 10);
  const ids = await watchlistMovieIds(db);
  for (const id of ids) {
    try {
      const stateRef = db.doc(`notificationState/movie_${id}`);
      const state = (await stateRef.get()).data();
      if (state?.notifiedRelease) continue;
      const movie = await tmdb(`/movie/${id}`);
      if (movie?.release_date !== today) continue;

      const fids = await followerFids(db, 'movies', id, onWatchlist);
      if (fids.length) {
        await sendPush({
          fids,
          title: `🎬 ${movie.title}`,
          body: 'Now in theaters!',
          type: 'movie',
          id,
          imagePath: movie.backdrop_path,
        });
      }
      await stateRef.set({ notifiedRelease: true }, { merge: true });
      log(`${movie.title}: released (${fids.length})`);
    } catch (e) {
      log(`Failed to check movie ${id}: ${e.message}`);
    }
  }
  log(`Checked ${ids.length} watchlist movies.`);
}

module.exports = { notifyMovieReleases };
