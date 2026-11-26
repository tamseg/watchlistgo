const functions = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { refreshSeries } = require('./tv/refresh');
const { releaseEpisodes } = require('./tv/release');
const { notifyMovieReleases } = require('./movies');

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
