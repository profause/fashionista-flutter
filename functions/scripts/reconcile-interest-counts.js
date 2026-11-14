/* eslint-disable */
/**
 * Rebuilds `fashion_interests.number_of_posts` from the actual `trends` data.
 *
 * This runs the same logic as the admin-only `reconcileFashionInterestPostCounts`
 * callable, but directly with the Admin SDK so it can be run from a trusted
 * machine without minting a custom-claim user or calling HTTPS.
 *
 * Authentication, in order of preference:
 *   1. GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   2. Application Default Credentials (`gcloud auth application-default login`)
 *
 * Never commit the service-account key.
 *
 * Usage:
 *   cd functions
 *   npm run build
 *   GOOGLE_APPLICATION_CREDENTIALS=~/fashionista-service-account.json \
 *     FIREBASE_PROJECT_ID=fashionista-2025 \
 *     node scripts/reconcile-interest-counts.js
 */

const admin = require('firebase-admin');
const {
  ReconcileRepository,
  rebuildFashionInterestPostCounts,
} = require('../lib/trends/reconcile');

const projectId =
  process.env.FIREBASE_PROJECT_ID ||
  process.env.GCLOUD_PROJECT ||
  'fashionista-2025';

admin.initializeApp({ projectId });

const db = admin.firestore();

rebuildFashionInterestPostCounts(new ReconcileRepository(db))
  .then((summary) => {
    console.log('Rebuilt fashion interest post counts:', summary);
  })
  .catch((error) => {
    console.error('Failed to rebuild fashion interest post counts:', error);
    process.exitCode = 1;
  });
