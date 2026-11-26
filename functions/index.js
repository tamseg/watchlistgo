const functions = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall } = require('firebase-functions/v2/https');
const { requestSeries } = require('./tv/request');
const { refreshSeries, resolveNewFollow } = require('./tv/refresh');
const { releaseEpisodes } = require('./tv/release');
const { followChanged, updateFollowerCount } = require('./tv/followers');
const { takeQuota } = require('./tv/quota');
const { notifyMovieReleases } = require('./movies');
const { proxyTmdb } = require('./tmdb');

initializeApp();

const region = 'europe-west3';

exports.refreshSeries = functions.scheduler.onSchedule(
  {
    region,
    schedule: '30 7,13,19 * * *',
    timeoutSeconds: 540,
    memory: '256MiB',
  },
  async () => {
    await refreshSeries({ db: getFirestore(), dryRun: false });
  },
);

exports.resolveFollowedSeries = onDocumentWritten(
  {
    document: 'users/{uid}/series/{tmdbId}',
    region: 'me-west1',
    timeoutSeconds: 120,
    memory: '256MiB',
  },
  async event => {
    const db = getFirestore();
    const tmdbId = Number(event.params.tmdbId);
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (followChanged(before, after)) await updateFollowerCount(db, tmdbId);
    const allowed = async () => (await takeQuota(db, 1)) > 0;
    await resolveNewFollow({ db, tmdbId, before, after, allowed });
  },
);

exports.requestSeries = onCall(
  { region: 'me-west1', timeoutSeconds: 300, memory: '256MiB' },
  async request => {
    if (!request.app) console.warn('requestSeries called without App Check');
    return requestSeries({
      db: getFirestore(),
      tmdbIds: request.data?.tmdbIds,
    });
  },
);

exports.tmdb = onCall(
  { region: 'me-west1', timeoutSeconds: 30, memory: '256MiB' },
  async request => {
    if (!request.app) console.warn('tmdb called without App Check');
    return proxyTmdb(request.data);
  },
);

exports.releaseEpisodes = functions.scheduler.onSchedule(
  { region, schedule: '0 * * * *', timeoutSeconds: 120, memory: '256MiB' },
  async () => {
    await releaseEpisodes({ db: getFirestore() });
  },
);

exports.checkAndNotify = functions.scheduler.onSchedule(
  {
    region,
    schedule: '0 8,14,20 * * *',
    timeoutSeconds: 540,
    memory: '256MiB',
  },
  async () => {
    await notifyMovieReleases({ db: getFirestore() });
  },
);
