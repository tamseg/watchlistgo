const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

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
      const db = admin.firestore();
      const usersSnap = await db.collection('users').get();
      const tvSubscribers = {};
      const movieSubscribers = {};
      usersSnap.docs.forEach(doc => {
        const data = doc.data();
        if (!data.fcmToken)
          return;
        const token = data.fcmToken;
        const series = data.followedSeriesIds || [];
        const movies = data.followedMoviesIds || [];
        series.forEach(sId => {
          if (!tvSubscribers[sId])
            tvSubscribers[sId] = [];
          tvSubscribers[sId].push(token);
        });
        movies.forEach(mId => {
          if (!movieSubscribers[mId])
            movieSubscribers[mId] = [];
          movieSubscribers[mId].push(token);
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
             pushesToSend.push({
               tokens: tvSubscribers[tvId],
               title: `📺 ${tv.name}`,
               body: `Season ${numSeasons} has been announced!`,
               type: 'tv', id: String(tvId),
               ...(tv.backdrop_path && { imageUrl: `https://image.tmdb.org/t/p/w500${tv.backdrop_path}` })
             });
             updatedState.lastNotifiedSeason = numSeasons;
          }
          const nextEpisode = tv.next_episode_to_air;
          if (nextEpisode && nextEpisode.air_date === today)
          {
            const epString = `S${nextEpisode.season_number}E${nextEpisode.episode_number}`;
            if (updatedState.lastNotifiedEpisode !== epString)
            {
              pushesToSend.push({
                tokens: tvSubscribers[tvId],
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
              tokens: movieSubscribers[movieId],
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
        for (let i = 0; i < push.tokens.length; i += 500)
        {
          const batchTokens = push.tokens.slice(i, i + 500);
          await admin.messaging().sendEachForMulticast({
            tokens: batchTokens,
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

exports.testPushNotification = functions.https.onRequest(
  { region: 'europe-west3' },
  async (req, res) => {
  try {
    const db = admin.firestore();
    const usersSnap = await db.collection('users').get();
    let sentCount = 0;

    for (const doc of usersSnap.docs)
    {
      const data = doc.data();
      if (!data.fcmToken)
        continue;

      const series = data.followedSeriesIds || [];
      const movies = data.followedMoviesIds || [];

      if (series.length > 0)
      {
        const tvId = series[0];
        const tvRes = await tmdbApi.get(`/tv/${tvId}`);
        const tv = tvRes.data;

        await admin.messaging().send({
          token: data.fcmToken,
          notification: {
            title: `📺 [TEST] ${tv.name}`,
            body: `New Episode S1E1 airs today!`,
            ...(tv.backdrop_path && { imageUrl: `https://image.tmdb.org/t/p/w500${tv.backdrop_path}` }),
          },
          data: { type: 'tv', id: String(tvId) },
          android: {
            notification: {
              channelId: 'watchlstgo_notifications',
            }
          }
        });
        sentCount++;
      }

      if (movies.length > 0)
      {
        const movieId = movies[0];
        const movieRes = await tmdbApi.get(`/movie/${movieId}`);
        const movie = movieRes.data;

        await admin.messaging().send({
          token: data.fcmToken,
          notification: {
            title: `🎬 [TEST] ${movie.title}`,
            body: `Now in theaters!`,
            ...(movie.backdrop_path && { imageUrl: `https://image.tmdb.org/t/p/w500${movie.backdrop_path}` }),
          },
          data: { type: 'movie', id: String(movieId) },
          android: {
            notification: {
              channelId: 'watchlstgo_notifications',
            }
          }
        });
        sentCount++;
      }
    }

    res.status(200).send(`Sent ${sentCount} test notifications.`);
  } catch (e) {
    console.error('Test notification error:', e);
    res.status(500).send(`Error: ${e.message}`);
  }
});
