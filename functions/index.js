const functions = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const axios = require('axios');
const { refreshSeries } = require('./tv/refresh');

initializeApp();

exports.refreshSeries = functions.scheduler.onSchedule(
  {
    region: 'europe-west3',
    schedule: '30 7,13,19 * * *',
    timeoutSeconds: 540,
    memory: '256MiB',
  },
  async () => {
    await refreshSeries({ db: getFirestore(), dryRun: true });
  },
);

const TMDB_ACCESS_TOKEN = process.env.TMDB_ACCESS_TOKEN;

const tmdbApi = axios.create({
  baseURL: 'https://api.themoviedb.org/3',
  headers: {
    Authorization: `Bearer ${TMDB_ACCESS_TOKEN}`,
    'Content-Type': 'application/json;charset=utf-8',
  },
});

exports.checkAndNotify = functions.scheduler.onSchedule(
  {
    region: 'europe-west3',
    schedule: '0 8,14,20 * * *',
    timeoutSeconds: 540,
    memory: '256MiB',
  },
  async () => {
    try {
      console.log('Started daily checkAndNotify...');
      const db = getFirestore();
      const usersSnap = await db.collection('users').get();
      const tvSubscribers = {};
      const movieSubscribers = {};
      usersSnap.docs.forEach(doc => {
        const data = doc.data();
        if (!data.fid)
          return;
        const fid = data.fid;
        const series = data.followedSeriesIds || [];
        const movies = data.followedMoviesIds || [];
        series.forEach(sId => {
          if (!tvSubscribers[sId])
            tvSubscribers[sId] = [];
          tvSubscribers[sId].push(fid);
        });
        movies.forEach(mId => {
          if (!movieSubscribers[mId])
            movieSubscribers[mId] = [];
          movieSubscribers[mId].push(fid);
        });
      });
      console.log(`Found ${Object.keys(tvSubscribers).length} unique TV shows and ${Object.keys(movieSubscribers).length} unique movies to check.`);
      const today = new Date().toISOString().split('T')[0];
      const stateUpdates = {};
      const pushesToSend = [];
      for (const tvId of Object.keys(tvSubscribers))
      {
        try {
          const res = await tmdbApi.get(`/tv/${tvId}`);
          const tv = res.data;
          const stateRef = db.collection('notificationState').doc(`tv_${tvId}`);
          const stateSnap = await stateRef.get();
          const state = stateSnap.exists ? stateSnap.data() : { lastNotifiedSeason: 0, lastNotifiedEpisode: '' };
          let updatedState = { ...state };
          const numSeasons = tv.number_of_seasons || 0;
          if (numSeasons > state.lastNotifiedSeason && numSeasons > 0)
          {
             const latestSeason = (tv.seasons || []).find(s => s.season_number === numSeasons);
             const airDate = latestSeason ? latestSeason.air_date : null;
             const isPast = airDate && airDate < today;
             if (stateSnap.exists && !isPast)
             {
               pushesToSend.push({
                 fids: tvSubscribers[tvId],
                 title: `📺 ${tv.name}`,
                 body: `Season ${numSeasons} has been announced!`,
                 type: 'tv', id: String(tvId),
                 ...(tv.backdrop_path && { imageUrl: `https://image.tmdb.org/t/p/w500${tv.backdrop_path}` })
               });
             }
             updatedState.lastNotifiedSeason = numSeasons;
          }
          const nextEpisode = tv.next_episode_to_air;
          if (nextEpisode && nextEpisode.air_date === today)
          {
            const epString = `S${nextEpisode.season_number}E${nextEpisode.episode_number}`;
            if (updatedState.lastNotifiedEpisode !== epString)
            {
              pushesToSend.push({
                fids: tvSubscribers[tvId],
                title: `📺 ${tv.name}`,
                body: `New Episode ${epString} airs today!`,
                type: 'tv', id: String(tvId),
                ...(tv.backdrop_path && { imageUrl: `https://image.tmdb.org/t/p/w500${tv.backdrop_path}` })
              });
              updatedState.lastNotifiedEpisode = epString;
            }
          }
          if (updatedState.lastNotifiedSeason !== state.lastNotifiedSeason ||
              updatedState.lastNotifiedEpisode !== state.lastNotifiedEpisode)
          {
            stateUpdates[`tv_${tvId}`] = updatedState;
          }
        } catch (e) {
          console.error(`Error checking TV show ${tvId}:`, e.message);
        }
      }
      for (const movieId of Object.keys(movieSubscribers))
      {
        try {
          const res = await tmdbApi.get(`/movie/${movieId}`);
          const movie = res.data;
          const stateRef = db.collection('notificationState').doc(`movie_${movieId}`);
          const stateSnap = await stateRef.get();
          const state = stateSnap.exists ? stateSnap.data() : { notifiedRelease: false };
          if (movie.release_date === today && !state.notifiedRelease)
          {
            pushesToSend.push({
              fids: movieSubscribers[movieId],
              title: `🎬 ${movie.title}`,
              body: `Now in theaters!`,
              type: 'movie', id: String(movieId),
              ...(movie.backdrop_path && { imageUrl: `https://image.tmdb.org/t/p/w500${movie.backdrop_path}` })
            });
            stateUpdates[`movie_${movieId}`] = { notifiedRelease: true };
          }
        } catch (e) {
          console.error(`Error checking movie ${movieId}:`, e.message);
        }
      }
      console.log(`Sending ${pushesToSend.length} notification batches...`);
      for (const push of pushesToSend)
      {
        for (let i = 0; i < push.fids.length; i += 500)
        {
          const batchFids = push.fids.slice(i, i + 500);
          await getMessaging().sendEachForMulticast({
            fids: batchFids,
            notification: {
              title: push.title,
              body: push.body,
              ...(push.imageUrl && { imageUrl: push.imageUrl }),
            },
            data: {
              type: push.type,
              id: push.id,
            },
            android: {
              notification: {
                channelId: 'watchlstgo_notifications',
              }
            }
          });
        }
      }
      if (Object.keys(stateUpdates).length > 0)
      {
        console.log(`Updating ${Object.keys(stateUpdates).length} notification state records...`);
        let batch = db.batch();
        let count = 0;
        for (const [docId, stateData] of Object.entries(stateUpdates))
        {
          const ref = db.collection('notificationState').doc(docId);
          batch.set(ref, stateData, { merge: true });
          count++;
          if (count === 490)
          {
            await batch.commit();
            batch = db.batch();
            count = 0;
          }
        }
        if (count > 0)
          await batch.commit();
      }
      console.log('checkAndNotify completed successfully.');
    } catch (e) { console.error('Critical error in checkAndNotify:', e); }
  }
);
