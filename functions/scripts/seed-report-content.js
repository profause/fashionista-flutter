/* eslint-disable */
/**
 * Seeds the trend-report picker and its threshold config.
 *
 * Run with Application Default Credentials available, for example:
 *   gcloud auth application-default login
 *   FIREBASE_PROJECT_ID=fashionista-2025 npm run seed:reports
 *
 * The script is idempotent: reason documents are overwritten, while the
 * threshold config is merged.
 */

const admin = require('firebase-admin');

const projectId =
  process.env.FIREBASE_PROJECT_ID ||
  process.env.GCLOUD_PROJECT ||
  'fashionista-2025';

admin.initializeApp({ projectId });

const db = admin.firestore();

const reviewNote =
  "We usually review all submitted reports within 48 hours. We won't notify this account that you submitted a report.";

const reasons = [
  {
    id: 'misleading',
    title: 'Misleading content',
    description: 'Claims or behaviour that mislead people',
    order: 1,
    content: `${reviewNote}

**We remove things like**
- Misleading content or behaviour
- Impersonation or fake accounts
- Claims that cannot be supported by the post`,
  },
  {
    id: 'repetitive',
    title: 'Repetitive posts',
    description: 'The same content posted repeatedly',
    order: 2,
    content: `${reviewNote}

**We remove things like**
- Repetitive posts
- Duplicated captions or media
- Posts that flood the feed with the same content`,
  },
  {
    id: 'unsolicited_commercial',
    title: 'Unsolicited commercial messages',
    description: 'Spam, scams or unrequested promotions',
    order: 3,
    content: `${reviewNote}

**We remove things like**
- Unsolicited commercial messages
- Spam links or scam offers
- Promotions that are not relevant to the post`,
  },
];

async function main() {
  const batch = db.batch();

  for (const reason of reasons) {
    const { id, ...data } = reason;
    batch.set(
      db.collection('report_trend_content').doc(id),
      {
        ...data,
        is_active: true,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  batch.set(
    db.collection('app_config').doc('trend_reporting'),
    { threshold: 5, enabled: true },
    { merge: true }
  );

  await batch.commit();
  console.log(`Seeded ${reasons.length} report reasons for ${projectId}.`);
}

main().catch((error) => {
  console.error('Failed to seed report content:', error);
  process.exitCode = 1;
});
